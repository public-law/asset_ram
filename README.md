# AssetRam

## tldr;

Change template lines like this:

```ruby
<%= javascript_include_tag('application.js') %>
```

to this:

```ruby
<%= AssetRam.cache { javascript_include_tag('application.js') } %>
```

## Performance testing

**Rails 7 update: I measured a 35% reduction in allocations.** I tested 
[my app's home page](https://www.public.law) in production:

* Rails 7.0.6
* Ruby 3.2.2
* Sprockets v3 and v4
* JE_MALLOC
* `--enable-yjit`

The page is simple with only five images. If you have more, you'll get 
an even bigger boost:

<img src="https://github.com/dogweather/asset_ram/raw/master/test-data.png" alt="Test Data" style="width: 70%;">

The savings come from avoiding asset calculations. The app is faster, too.
But it's hard for me to measure precisely: enabling AssetRam, this page time
goes down from ~9ms to ~6ms.


> [!TIP]
> Set env var `ASSET_RAM_DISABLE` to do this comparison in your own app.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'asset_ram'
```

And then execute:

```
$ bundle install
```


## Usage

Wrap every asset helper call with `#cache` so that code reading `xyz` becomes `AssetRam.cache { xyz }`.

**Real examples from my app:**

### Before

```ruby
<%= favicon_link_tag('favicon/favicon.ico', rel: 'icon') %>
# ...
<%= javascript_include_tag('application.js') %>
```


### After

```ruby
<%= AssetRam.cache { favicon_link_tag('favicon/favicon.ico', rel: 'icon') } %>
# ...
<%= AssetRam.cache { javascript_include_tag('application.js') } %>
```


After booting up, AssetRam sends a message like this _once_ to the log for each usage:

```
Caching ["/website/app/views/application/_favicon.haml", 8]
```

It outputs this when the asset link is generated. It shows the full cache key (filename
and line number)
so we can see what it's caching. This is the line of code that, without AssetRam,
would be exectued on every request.


I use it in my footer for social icons as well. I **used to** have this in my `_footer_for_screen.haml`:

```ruby
= link_to AssetRam.cache { image_tag("social/instagram-logo.svg", alt: 'Instagram', loading: 'lazy', decoding: 'async') },      "https://www.instagram.com/law.is.code/"
= link_to AssetRam.cache { image_tag("social/facebook-logo-button.svg", alt: 'Facebook', loading: 'lazy', decoding: 'async') }, "https://www.facebook.com/PublicDotLaw"
= link_to AssetRam.cache { image_tag("social/twitter-logo-button.svg", alt: 'Twitter', loading: 'lazy', decoding: 'async') },   "https://twitter.com/law_is_code"
= link_to AssetRam.cache { image_tag("social/github-logo.svg", alt: 'Our GitHub Page', loading: 'lazy', decoding: 'async') },   "https://www.github.com/public-law/"
```


But my whole footer partial is static. So now I changed the application layout from this:

```ruby
render 'footer_for_screen'
```

to this, which caches the whole partial with one `#cache` call:

```ruby
= AssetRam.cache { render 'footer_for_screen' }
```


### In some cases, the cache key can't be inferred.

AssetRam creates the cache key automatically using the view's source filename and line number.
This works for most uses. 

Some of my app's views are an exception, however. It's **multi-tenant** and the views serve content
for many sub-domains. To handle this, the call to `#cache` allows extra key info to be passed.
In my HTML `head` view, I already had a `site` variable for choosing the CSS file for the domain. So I reuse that as extra cache key info:

```ruby
<%= AssetRam.cache(key: site) { stylesheet_link_tag("themes/#{site}", media: nil) } %>
```

## Background: I was looking for ways to reduce allocations in my Rails app

In an effort to help my app run in a small 512MB virtual server, I looked through every view
invocation in the logs. After I optimized a bunch of my code, I realized that the asset helpers
create a relatively large amount of objects. The code is pretty complex too implying some amount
of CPU overhead. Moreover, this work is **repeated on every request**.

These asset fingerprints are potentially re-generated on every deploy. Maybe I edit an image, but
I haven't modified any ActiveRecord models. This means that **the asset links cannot be stored in
the standard Rails cache.** (If the Rails cache had a lifetime option of, "until next boot", that would solve the problem.)

> [!NOTE]
> This is when I realized that storing the computed paths in a simple hash (in RAM only) would be fast and never
> return stale data: The RAM cache goes away on a deploy/restart, which is
> when asset fingerprints could change.

And so one-by-one I started storing the computed asset paths in a hash, and saw pretty dramatic results.

## How it works: Block-based code executed in the view's context and inferred cache keys

Rails has some magic around when the asset helpers are able to create the fingerprint path. I found
that the caching needs to be done within the context of a view. This is why the lib's API looks
the way it does. 

To make it as easy as possible to use, the lib finds the view's source filename and the line number of
the code being cached. This has been working well and in production for ~~four months~~ years in a large Rails app.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
