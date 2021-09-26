# AssetRam

In a nutshell, for [a typical dynamic page](https://texas.public.law/statutes/tex._fam._code_section_1.001) in my Rails app, I get:

* 71% reduction in execution time
* 83% reduction in allocations

My app has been amazingly efficient since using these: memory usage stays flat at just 50% usage for 4 Puma workers. It's very quick, with production response times averaging 37ms a Heroku Standard-2x Dyno.


## Example stats from development mode (production is similar)

Without AssetRam:

```
Completed 200 OK in 38ms (Views: 34.2ms | ActiveRecord: 0.9ms | Allocations: 30332)
```

With AssetRam:

```
Completed 200 OK in 11ms (Views: 5.1ms | ActiveRecord: 1.3ms | Allocations: 5208)
```


## Usage

Wrap every asset helper call with `#cache`, like this:

### Before

```ruby
= favicon_link_tag('favicon/favicon.ico', rel: 'icon')
```

### After

```ruby
= AssetRam::Helper.cache { favicon_link_tag('favicon/favicon.ico', rel: 'icon') }
```

### In some cases, the cache key can't be inferred.

RamCache creates the cache key automatically using the view source filename and line number.
This works for most uses. 

Some of my app's views are an exception, however. It's multi-tenant and the views serve content
for several sub-domains. And so the call to `#cache` allows extra key info to be passed.
In my HTML HEAD view, I have a `site` variable for choosing the CSS file for the domain:

```
= AssetRam::Helper.cache(key: site) { stylesheet_link_tag("themes/#{site}", media: nil) }
```

## Background: I was looking for ways to reduce allocations in my Rails app

In an effort to help my app run in a small 512MB virtual server, I looked through every view
invocation in the logs. After I optimized a bunch of my code, I realized that the asset helpers
create a relatively large amount of objects. The code is pretty complex too implying some amount
of CPU overhead. Worst of all, this work is done over on every request.

These asset fingerprints are potentially re-generated on every deploy. So they can't be stored in
the usual Rails cache. I realized that storing the computed paths in a simple hash (in RAM only)
would be fast and never return stale data: The RAM cache goes away on a deploy/restart, which is
when asset fingerprints could change.

And so one-by-one I started storing the computed asset paths in a hash, and saw pretty dramatic results.

## How it works: Block-based code executed in the view's context and inferred cache keys

There's some magic around when the asset helpers are able to create the fingerprint path. I found
that the caching needs to be done within the context of a view. This is why the lib's API looks
the way it does. 

To make it as easy as possible to use, the lib finds the view's source filename and the line number of
the code being cached. This has been working well and in production for four months in a large Rails app.



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'asset_ram'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install asset_ram


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
