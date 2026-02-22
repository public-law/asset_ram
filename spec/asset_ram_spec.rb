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
      AssetRam::Helper.class_variable_set(:@@_cumulative_size, 0)
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

    it "tracks cumulative byte size of cached values" do
      AssetRam.cache(key: :a) { "hello" }
      AssetRam.cache(key: :b) { "world!" }
      cumulative = AssetRam::Helper.class_variable_get(:@@_cumulative_size)
      expect(cumulative).to eq("hello".bytesize + "world!".bytesize)
    end
  end

  describe ".cache when APP_REVISION is set" do
    let(:logger) { double("Logger", warn: nil) }
    let(:fake_cache_store) { {} }
    let(:fake_cache) do
      store = fake_cache_store
      double("Cache").tap do |c|
        allow(c).to receive(:fetch) do |key, &block|
          store.fetch(key) { store[key] = block.call }
        end
      end
    end
    let(:counter) { SimpleCounter.new }

    before do
      stub_const("AssetRam::APP_REVISION", "abc123")
      stub_const("Rails", double("Rails", logger: logger, cache: fake_cache))
      AssetRam::Helper.class_variable_get(:@@_cache).clear
      AssetRam::Helper.class_variable_set(:@@_cumulative_size, 0)
    end

    def cached_counter(counter, key: '')
      AssetRam.cache(key: key) { counter.increment! }
    end

    class SimpleCounter
      attr_reader :value
      def initialize; @value = 0; end
      def increment!; @value += 1; end
    end

    it "caches the result via Rails.cache" do
      result1 = cached_counter(counter)
      result2 = cached_counter(counter)
      expect(result1).to eq(1)
      expect(result2).to eq(1)
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

    it "does not populate @@_cache" do
      cached_counter(counter)
      expect(AssetRam::Helper.class_variable_get(:@@_cache)).to be_empty
    end

    it "includes the revision in the Rails.cache key" do
      cached_counter(counter)
      keys = fake_cache_store.keys
      expect(keys.first).to start_with("asset_ram/abc123/")
    end
  end
end
