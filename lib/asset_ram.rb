# frozen_string_literal: true

require_relative "asset_ram/version"

#
# Use in views to cache the asset path computation.
#
# Preferred usage (since v1.1.0):
#
#   = AssetRam.cache { favicon_link_tag('favicon/favicon.ico', rel: 'icon') }
#
# The calculated asset paths are keyed by source file name and line number.
# The results are stored in RAM.
#
# Sometimes, a key is needed if the code is run in different contexts, like
# a multi-tenant site:
#
#   = AssetRam.cache(key: site) { stylesheet_link_tag("themes/#{site}", media: nil) }
#
# For compatibility, you can still use:
#
#   = AssetRam::Helper.cache { ... }
#
# To test and compare if this lib actually improves performance,
# set the ASSET_RAM_DISABLE env var and it will transparently never cache.
#
#
module AssetRam
  class Error < StandardError; end

  _rev = ENV['APP_REVISION']
  APP_REVISION = (_rev.nil? || _rev.empty?) ? nil : _rev.freeze

  ##
  # The simpler API: AssetRam.cache { ... }
  #
  def self.cache(key: '', &blk)
    Helper.cache(key: key, &blk)
  end

  ##
  # Our own asset helper which memoizes Rails' asset helper calls.
  #
  # Entries are nested by source path, line and key, so a cache hit only
  # looks up those three values and never builds a composite key.
  #
  class Helper
    @@_cache = {}
    @@_rails_keys = {}
    @@_cumulative_size = 0

    NO_KEY = Object.new.freeze


    def self.cache(key: '', &blk)
      return yield if ENV['ASSET_RAM_DISABLE']

      path, line = blk.source_location
      key = NO_KEY if blank_key?(key)

      if rails_cache?
        fetch_from_rails_cache(rails_cache_key(path, line, key), &blk)
      else
        entries = slot(@@_cache, path, line)
        entries.fetch(key) { entries[key] = remember(location_name(path, line, key), &blk) }
      end
    end


    def self.cache_by_key(cache_key, &blk)
      return yield if ENV['ASSET_RAM_DISABLE']

      if rails_cache?
        fetch_from_rails_cache("asset_ram/#{APP_REVISION}/#{cache_key.join('/')}", &blk)
      else
        @@_cache.fetch(cache_key) { @@_cache[cache_key] = remember(cache_key, &blk) }
      end
    end


    def self.rails_cache?
      APP_REVISION && !ENV['ASSET_RAM_HASH_ONLY']
    end


    def self.fetch_from_rails_cache(rails_cache_key)
      Rails.cache.fetch(rails_cache_key) do
        Rails.logger.warn("Caching #{rails_cache_key} in Rails cache")
        yield
      end
    end


    def self.rails_cache_key(path, line, key)
      keys = slot(@@_rails_keys[APP_REVISION] ||= {}, path, line)
      keys.fetch(key) do
        keys[key] = "asset_ram/#{APP_REVISION}/#{location_name(path, line, key).join('/')}".freeze
      end
    end


    #
    # Cached strings are frozen copies, so no caller can alter what
    # every later page receives.
    #
    def self.remember(name)
      value = yield
      value = value.dup.freeze if value.is_a?(String) && !value.frozen?

      # Using WARN level because it should only output
      # once during any Rails run. If it's output multiple
      # times, then caching isn't working correctly.
      @@_cumulative_size += value.to_s.bytesize
      Rails.logger.warn("Caching #{name} in RAM cache (total size: #{@@_cumulative_size} bytes)")
      value
    end


    def self.slot(store, path, line)
      lines = store[path] ||= {}
      lines[line] ||= {}
    end


    def self.blank_key?(key)
      key.is_a?(String) || key.is_a?(Symbol) ? key.empty? : key.to_s.empty?
    end


    def self.location_name(path, line, key)
      key.equal?(NO_KEY) ? [path, line] : [path, line, key]
    end

    private_class_method :rails_cache?, :fetch_from_rails_cache, :rails_cache_key,
                         :remember, :slot, :blank_key?, :location_name
  end
end
