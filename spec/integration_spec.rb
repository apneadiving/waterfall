require 'spec_helper'

describe 'Wf' do
  let(:dummy) { { } }
  it 'chain instructions, no error' do
    Wf.new
      .then(->{ dummy[:yo] = true })
      .then(Service.new(dummy))
      .then(Service2.new)
      .then(Service3.new)
      .then(->(du){ du[:bash] = true })
      .catch(->{ dummy[:error] = true })

    expect(dummy[:yo]).to be_true
    expect(dummy[:service]).to be_true
    expect(dummy[:service2]).to be_true
    expect(dummy[:service3]).to be_true
    expect(dummy[:bash]).to be_true
    expect(dummy[:error]).to_not be_true
  end

  it 'chain instructions, no error' do
    Wf.new
      .then do
        dummy[:yo] = true
      end
      .then(Service.new(dummy))
      .then(Service2.new)
      .then(Service3.new)
      .then do |du|
        du[:bash] = true
      end
      .catch do
        dummy[:error] = true
      end

    expect(dummy[:yo]).to be_true
    expect(dummy[:service]).to be_true
    expect(dummy[:service2]).to be_true
    expect(dummy[:service3]).to be_true
    expect(dummy[:bash]).to be_true
    expect(dummy[:error]).to_not be_true
  end

  it 'works' do
    Wf.new
      .then(ErrorService.new)
      .catch(->(error){ dummy[:error] = error })
    expect(dummy[:error]).to eq('ErrorService')
  end

  it 'works' do
    Wf.new
      .tap(->(s){ @sery = s })
      .then(->{ dummy[:yo] = true })
      .then(Service.new(dummy))
      .then(->{ @sery.reject('inside') })
      .then(Service2.new)
      .then(Service3.new)
      .then(->{ dummy[:bash] = true })
      .catch do |error|
        dummy[:error] = error
      end

    expect(dummy[:yo]).to be_true
    expect(dummy[:service]).to be_true
    expect(dummy[:service2]).to_not be_true
    expect(dummy[:service3]).to_not be_true
    expect(dummy[:bash]).to_not be_true
    expect(dummy[:error]).to eq 'inside'
  end

  it 'with subsery' do
    Wf.new
      .then(SubWf.new(dummy))

    expect(dummy[:sub1]).to be_true
    expect(dummy[:sub2]).to be_true
  end

  it 'with subsery and error' do
    Wf.new
      .then(SubWfErr.new(dummy))
      .catch do |error|
        dummy[:error] = error
      end

    expect(dummy[:sub2]).to_not be_true
    expect(dummy[:error]).to eq 'sub1'
  end

  it 'with explicit nil errors' do
    Wf.new
      .then(SubWfWithNilErrors.new)
      .catch do |error|
        dummy[:error] = error
      end
    expect(dummy[:error]).to eq 'foo is missing'
  end

end
