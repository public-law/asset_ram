## [1.2.0] - 2026-02-21

- When the `APP_REVISION` env var is set, use `Rails.cache` (e.g., memcached) instead of a per-process Ruby hash. The cache key is prefixed with the revision, so it naturally invalidates on deploy. This allows sharing cached asset paths across Puma workers, reducing RAM usage and speeding up startups.

## [1.1.0] - 2025-06-12

- Added a new, simpler API: `AssetRam.cache { ... }` as the preferred way to cache asset computations in views. The legacy `AssetRam::Helper.cache` API is still supported for compatibility.
- Improved documentation to highlight the new API and update usage examples.
- Added comprehensive RSpec tests for caching behavior, keying, and environment variable handling.


## [0.1.0] - 2021-09-25

- Initial release
