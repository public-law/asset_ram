# frozen_string_literal: true

RSpec.describe AssetRam do
  it "has a version number" do
    expect(AssetRam::VERSION).not_to be nil
  end

  describe ".cache" do
    let(:logger) { double("Logger", warn: nil) }

    before do
      stub_const("Rails", double("Rails", logger: logger))
      AssetRam::Helper.class_variable_get(:@@_cache).clear
    end

    it "caches the result of the block" do
      counter = 0
      result1 = AssetRam.cache { counter += 1 }
      result2 = AssetRam.cache { counter += 1 }
      expect(result1).to eq(1)
      expect(result2).to eq(1)
    end

    it "uses the key argument as part of the cache key" do
      counter = 0
      result1 = AssetRam.cache(key: :foo) { counter += 1 }
      result2 = AssetRam.cache(key: :bar) { counter += 1 }
      expect(result1).to eq(1)
      expect(result2).to eq(2)
    end

    it "does not cache if ASSET_RAM_DISABLE is set" do
      counter = 0
      begin
        ENV["ASSET_RAM_DISABLE"] = "1"
        result1 = AssetRam.cache { counter += 1 }
        result2 = AssetRam.cache { counter += 1 }
        expect(result1).to eq(1)
        expect(result2).to eq(2)
      ensure
        ENV.delete("ASSET_RAM_DISABLE")
      end
    end
  end
end
