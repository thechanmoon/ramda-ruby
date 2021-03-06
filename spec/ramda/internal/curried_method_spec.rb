require 'spec_helper'

describe Ramda::Internal::CurriedMethod do
  let(:klass) do
    Class.new do
      extend Ramda::Internal::CurriedMethod
      include Ramda::Internal::Java::MakeCurryProc if RUBY_PLATFORM == 'java'
    end
  end
  let(:instance) { klass.new }

  context '#curried_method' do
    it 'without placeholder' do
      klass.curried_method(:g) do |a, b, c|
        a + b + c
      end

      # expect(instance.sample_method.origin_arity).to be(3)
      expect(instance.g.call(1).call(2).call(3)).to be(6)
      expect(instance.g(1).call(2).call(3)).to be(6)
      expect(instance.g(1, 2).call(3)).to be(6)
      expect(instance.g(1, 2, 3)).to be(6)
    end

    it 'with placeholder' do
      klass.curried_method(:g) do |a, b, c|
        a + b + c
      end

      expect(instance.g(1, 2, 3)).to eq(6)
      expect(instance.g(R.__, 2, 3).call(1)).to eq(6)
      expect(instance.g(R.__, R.__, 3).call(1).call(2)).to eq(6)
      expect(instance.g(R.__, R.__, 3).call(1, 2)).to eq(6)
      expect(instance.g(R.__, 2, R.__).call(1, 3)).to eq(6)
      # expect(instance.g(R.__, 2).call(1).call(3)).to eq(6)
      # expect(instance.g(R.__, 2).call(1, 3)).to eq(6)
      # expect(instance.g(R.__, 2).call(R.__, 3).call(1)).to eq(6)
    end

    context 'exception handler' do
      before do
        klass.curried_method(:g) do |a, b, c|
          a + b + c
        end
      end

      after do
        Ramda.exception_handler = nil
      end

      it 'default behavior' do
        expect { instance.g(1, '', 2) }.to raise_error(/g -> String can't be coerced/)
      end

      it 'exception_handler=' do
        Ramda.exception_handler = ->(*) { raise 'ABC some exception' }
        expect { instance.g(1, '', 2) }.to raise_error(/ABC some exception/)
      end
    end
  end
end
