require 'spec_helper'

describe 'Wf' do
  let(:wf) { Wf.new }

  describe "chain" do

    it "yields wf outflow" do
      wf
        .chain  {|outflow| outflow[:bar] = 'bar' }
        .chain  {|outflow| @bar = outflow[:bar] }
      expect(wf.outflow[:bar]).to eq 'bar'
      expect(@bar).to eq 'bar'
    end

    it "assigns outflow's key the value of the block" do
      wf
        .chain(:bar) { 'bar' }
      expect(wf.outflow[:bar]).to eq 'bar'
    end

    context "wf internals" do
      it "dam from within" do
        wf
          .chain  {|outflow, waterfall| waterfall.dam('errrrr') }
          .on_dam {|error_pool| @errors = error_pool }

        expect(wf.dammed?).to be true
        expect(@errors).to eq 'errrrr'
      end

      it "outflow from within" do
        wf
          .chain {|outflow, waterfall| waterfall.outflow[:foo] = 1 }

        expect(wf.outflow[:foo]).to eq 1
      end
    end

    describe "chaining waterfalls" do

      shared_examples "a waterfall chain" do
        describe 'chain_wf' do
          it "takes expected vars only and rename them" do
            wf
              .chain_wf(baz: :foo) { waterfall }

            expect(wf.outflow).to_not have_key :foo
            expect(wf.outflow).to_not have_key :bar
            expect(wf.outflow[:baz]).to eq waterfall.outflow[:foo]
          end
        end
      end

      context "from an instance of a custom waterfall class" do
        class FakeService
          include Waterfall

          def call
            self
              .chain(:foo) { 1 }
              .chain(:bar) { 2 }
          end
        end

        let(:waterfall) { FakeService.new }

        it_behaves_like "a waterfall chain"

        context "only calls waterfall service if it was never called before" do
          it "when passed as an instance responding to call" do
            expect(waterfall).to receive(:call).once.and_call_original
            wf
              .chain { waterfall }
          end

          it "already called" do
            expect(waterfall).to receive(:call).once.and_call_original
            wf
              .chain { waterfall.call }
          end
        end
      end

      context "from a mere wf" do
        let(:waterfall) do
          Wf.new
            .chain(:foo) { 1 }
            .chain(:bar) { 2 }
        end

        it_behaves_like "a waterfall chain"
      end
    end
  end

  describe "when falsy" do
    let(:my_proc) { ->(val){ val } }

    def action(bool)
      wf
        .chain { wf.dam('dammed') if dam? }
        .when_falsy { my_proc.call(bool) }
          .dam  { 'err' }
        .chain  { @foo = 1 }
        .on_dam { |error_pool| @error = error_pool }
    end

    context "main context not dammed" do
      let(:dam?) { false }

      it "when actually falsy" do
        action false
        expect(@error).to eq 'err'
        expect(@foo).to_not eq 1
      end

      it "when actually truthy" do
        action true
        expect(@error).to_not eq 'err'
        expect(@foo).to eq 1
      end
    end

    context "main context dammed" do
      let(:dam?) { true }

      it "when actually falsy" do
        expect(my_proc).to_not receive(:call)
        action false
      end
    end
  end

  describe "when truthy" do
    let(:my_proc) { ->(val){ val } }

    def action(bool)
      wf
        .chain { wf.dam('dammed') if dam? }
        .when_truthy { my_proc.call(bool) }
          .dam  { 'err' }
        .chain  { @foo = 1 }
        .on_dam { |error_pool| @error = error_pool }
    end

    context "main context not dammed" do
      let(:dam?) { false }

      it "when actually falsy" do
        action false
        expect(@error).to_not eq 'err'
        expect(@foo).to eq 1
      end

      it "when actually truthy" do
        action true
        expect(@error).to eq 'err'
        expect(@foo).to_not eq 1
      end
    end

    context "main context dammed" do
      let(:dam?) { true }

      it "when actually truthy" do
        expect(my_proc).to_not receive(:call)
        action true
      end
    end
  end

  describe "error propagation" do
    class FailingChain
      include Waterfall

      def call
        self
          .chain {|error_pool, waterfall| waterfall.dam(self.class.error) }
      end

      def self.error
        'err'
      end
    end

    it "error propagates" do
      wf
        .chain { FailingChain.new }
        .chain    { @foo = 1 }
        .on_dam   { |error_pool| @error = error_pool }

      expect(@foo).to_not eq 1
      expect(@error).to eq FailingChain.error
    end
  end


  describe "rollback" do
    class FakeServiceBase
      include Waterfall
      def call
        self.chain { }
      end

      def rollback
      end
    end

    class MasterFakeService < FakeServiceBase
    end

    class FakeService1 < FakeServiceBase
      def call
        self.chain { SubFakeService1.new }
      end
    end

    class FakeService2 < FakeServiceBase
    end

    class FakeService3 < FakeServiceBase
      def call
        self.chain {|outflow, wf| wf.dam 'error' }
      end
    end

    class FakeService4 < FakeServiceBase
    end

    class SubFakeService1 < FakeServiceBase
    end

    it "doesnt call rollback if no on_dam" do
      expect_any_instance_of(MasterFakeService).to_not receive(:rollback)
      expect_any_instance_of(FakeService1).to_not receive(:rollback)
      expect_any_instance_of(SubFakeService1).to_not receive(:rollback)
      expect_any_instance_of(FakeService2).to_not receive(:rollback)
      expect_any_instance_of(FakeService3).to_not receive(:rollback)
      expect_any_instance_of(FakeService4).to_not receive(:rollback)

      MasterFakeService.new
        .chain { FakeService1.new }
        .chain { FakeService2.new }
        .chain { FakeService3.new }
        .chain { FakeService4.new }
    end

    it "calls rollback once on executed waterfalls" do
      expect_any_instance_of(MasterFakeService).to_not receive(:rollback)
      expect_any_instance_of(FakeService1).to receive(:rollback)
      expect_any_instance_of(SubFakeService1).to receive(:rollback)
      expect_any_instance_of(FakeService2).to receive(:rollback)
      expect_any_instance_of(FakeService3).to_not receive(:rollback)
      expect_any_instance_of(FakeService4).to_not receive(:rollback)

      MasterFakeService.new
        .chain { FakeService1.new }
        .chain { FakeService2.new }
        .chain { FakeService3.new }
        .chain { FakeService4.new }
        .on_dam   { }
        .on_dam   { }
    end

    it "doesnt call rollback if waterfall undammed" do
      expect_any_instance_of(MasterFakeService).to_not receive(:rollback)
      expect_any_instance_of(FakeService1).to_not      receive(:rollback)
      expect_any_instance_of(SubFakeService1).to_not   receive(:rollback)
      expect_any_instance_of(FakeService2).to_not      receive(:rollback)
      expect_any_instance_of(FakeService3).to_not      receive(:rollback)
      expect_any_instance_of(FakeService4).to_not      receive(:rollback)

      MasterFakeService.new
        .chain { FakeService1.new }
        .chain { FakeService2.new }
        .chain { FakeService3.new }
        .chain { FakeService4.new }
        .on_dam {|errors, waterfall| waterfall.undam }
    end

  end
end
