# AssetRam

In a nutshell, for [a typical page](https://texas.public.law/statutes/tex._fam._code_section_1.001) in my Rails app, I get:

* 71% reduction in execution time
* 83% reduction in allocations

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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dogweather/asset_ram.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
