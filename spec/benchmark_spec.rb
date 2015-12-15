require 'spec_helper'
require "benchmark"
require "ostruct"

describe 'basic scenario' do
  it 'with waterfall' do
    puts 'bwith'
    measure do
      1000000.times do
        Wf.new
          .chain(:bar) { 'bar' }
        end
    end
  end

  it 'without waterfall' do
    puts 'bwithout'
    measure do
      1000000.times do
        o = OpenStruct.new
        o.bar = 'bar'
      end
    end
  end
end

describe 'when_falsy scenario' do
  it 'with waterfall' do
    puts 'wwith'
    measure do
      1000000.times do
        Wf.new
          .when_falsy { false }
            .dam { 'err' }
          .chain(:bar) { 'bar' }
        end
    end
  end

  it 'without waterfall' do
    puts 'wwithout'
    measure do
      1000000.times do
        o = OpenStruct.new

        if false
          o.error = 'err'
        else
          o.bar = 'bar'
        end
      end
    end
  end
end

describe 'nested when_falsy scenario' do
  it 'with waterfall' do
    puts 'wwwith'
    measure do
      1000000.times do
        Wf.new
          .when_falsy { true }
            .dam { 'err' }
          .when_falsy { false }
            .dam { 'err' }
          .chain(:bar) { 'bar' }
        end
    end
  end

  it 'without waterfall' do
    puts 'wwwithout'
    measure do
      1000000.times do
        o = OpenStruct.new

        if false
          o.error = 'err'
        else
          if false
            o.error = 'err'
          else
            o.bar = 'bar'
          end
        end
      end
    end
  end
end

def measure(&block)
  no_gc = (ARGV[0] == "--no-gc")

  if no_gc
    GC.disable
  else
    # collect memory allocated during library loading
    # and our own code before the measurement
    GC.start
  end

  memory_before = `ps -o rss= -p #{Process.pid}`.to_i/1024
  gc_stat_before = GC.stat
  time = Benchmark.realtime do
    yield
  end

  puts ObjectSpace.count_objects
  unless no_gc
    GC.start(full_mark: true, immediate_sweep: true, immediate_mark: false)
  end

  puts ObjectSpace.count_objects
  gc_stat_after = GC.stat
  memory_after = `ps -o rss= -p #{Process.pid}`.to_i/1024

  puts({
    RUBY_VERSION => {
      gc: no_gc ? 'disabled' : 'enabled',
      time: time.round(2),
      gc_count: gc_stat_after[:count] - gc_stat_before[:count],
      memory: "%d MB" % (memory_after - memory_before)
    }
  }.to_json)
end
