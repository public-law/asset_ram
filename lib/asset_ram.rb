# frozen_string_literal: true

require_relative "asset_ram/version"

#
# Use in views to cache the asset path computation.
#
# For example, in a HAML file:
#
# = AssetRam::Helper.cache { favicon_link_tag('favicon/favicon.ico', rel: 'icon') }
#
# The calculated asset paths are keyed by source file name and line number.
# The results are stored in RAM.
#
# Sometimes, a key is needed if the code is run in different contexts, like
# a multi-tenant site:
#
# = AssetRam::Helper.cache(key: site) { stylesheet_link_tag("themes/#{site}", media: nil) }
#
#
module AssetRam
  class Error < StandardError; end

  ##
  # Our own asset helper which memoizes Rails' asset helper calls.
  class Helper

    ##
    # For testing the gains from caching with this library.
    # Set to true to disable caching.
    NO_CACHE = false

    @@_cache = {}


    def self.cache(key: '', &blk)
      return yield if NO_CACHE

      cache_key = blk.source_location
      cache_key << key if key.present?

      if !@@_cache.has_key?(cache_key)
        # Using WARN level because it should only be output
        # once during any Rails run. If its output multiple
        # times, then caching isn't working correctly.
        Rails.logger.warn("Caching #{cache_key}")
        @@_cache[cache_key] = yield
      end

      @@_cache.fetch(cache_key)
    end

  end
end
