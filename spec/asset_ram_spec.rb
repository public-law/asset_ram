# frozen_string_literal: true

RSpec.describe AssetRam do
  it "has a version number" do
    expect(AssetRam::VERSION).not_to be nil
  end

  describe ".cache" do
    let(:logger) { double("Logger", warn: nil) }
    let(:counter) { SimpleCounter.new }

    before do
      stub_const("Rails", double("Rails", logger: logger))
      AssetRam::Helper.class_variable_get(:@@_cache).clear
    end

    # Helper method to call AssetRam.cache from the **same source location**.
    def cached_counter(counter, key: '')
      AssetRam.cache(key: key) { counter.increment! }
    end

    # Simple counter object with increment! method
    class SimpleCounter
      attr_reader :value
      def initialize; @value = 0; end
      def increment!; @value += 1; end
    end


    it "caches the result of the block" do
      result1 = cached_counter(counter)
      result2 = cached_counter(counter)
      expect(result1).to eq(1)
      expect(result2).to eq(1)
    end

    it "does not cache if AssetRam isn't used" do
      # Really just verifying the `cached_counter` helper method.
      result1 = counter.increment!
      result2 = counter.increment!
      expect(result1).to eq(1)
      expect(result2).to eq(2)
    end

    it "uses the key argument as part of the cache key" do
      result1 = cached_counter(counter, key: :foo)
      result2 = cached_counter(counter, key: :bar)
      expect(result1).to eq(1)
      expect(result2).to eq(2)
    end

    it "does not cache if ASSET_RAM_DISABLE is set" do
      begin
        ENV["ASSET_RAM_DISABLE"] = "yes"
        result1 = cached_counter(counter)
        result2 = cached_counter(counter)
        expect(result1).to eq(1)
        expect(result2).to eq(2)
      ensure
        ENV.delete("ASSET_RAM_DISABLE")
      end
    end

    it "returns the value of the block" do
      expect(AssetRam.cache { 42 }).to eq(42)
    end

    it "supports the legacy Helper.cache API" do
      expect(AssetRam::Helper.cache { 123 }).to eq(123)
    end
  end
end
