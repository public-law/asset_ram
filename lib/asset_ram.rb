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
  class Helper
    @@_cache = {}
    @@_cumulative_size = 0


    def self.cache(key: '', &blk)
      cache_key = blk.source_location
      cache_key << key if !key.to_s.empty?

      cache_by_key(cache_key, &blk)
    end


    def self.cache_by_key(cache_key, &blk)
      return yield if ENV['ASSET_RAM_DISABLE']

      if APP_REVISION && !ENV['ASSET_RAM_HASH_ONLY']
        rails_cache_key = "asset_ram/#{APP_REVISION}/#{cache_key.join('/')}"
        Rails.cache.fetch(rails_cache_key) do
          Rails.logger.warn("Caching #{cache_key} in Rails cache")
          yield
        end
      else
        if !@@_cache.has_key?(cache_key)
          # Using WARN level because it should only output
          # once during any Rails run. If it's output multiple
          # times, then caching isn't working correctly.
          @@_cache[cache_key] = yield
          @@_cumulative_size += @@_cache[cache_key].to_s.bytesize
          Rails.logger.warn("Caching #{cache_key} in RAM cache (total size: #{@@_cumulative_size} bytes)")
        end

        @@_cache.fetch(cache_key)
      end
    end

  end
end
