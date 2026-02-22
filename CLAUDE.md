# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AssetRam is a Ruby gem that improves Rails performance by caching asset path calculations in RAM. It stores computed asset paths in a class-variable hash (`@@_cache`) keyed by source file name and line number, avoiding repeated asset fingerprint computations on every request. The cache naturally invalidates on deploy/restart.

## Commands

- **Run all tests:** `rake spec`
- **Run a single test:** `rspec spec/asset_ram_spec.rb -e "test name"`
- **Install dependencies:** `bin/setup`
- **Interactive console:** `bin/console`
- **Build/release gem:** `rake build` / `rake release`

## Architecture

This is a small, single-module gem. The entire implementation is in `lib/asset_ram.rb`:

- `AssetRam.cache(key: '') { block }` — primary public API, delegates to `Helper.cache`
- `AssetRam::Helper.cache` — uses `blk.source_location` (filename + line number) as the cache key; an optional `key:` param supports multi-tenant scenarios where the same source line produces different output
- `AssetRam::Helper.cache_by_key` — the actual memoization logic; skips caching when `ENV['ASSET_RAM_DISABLE']` is set
- Tests stub `Rails.logger` since the gem depends on Rails at runtime but doesn't require it as a gem dependency
