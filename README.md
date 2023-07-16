# AssetRam

## Rails 7 update: 35% reduction in allocations measured

I just did a test using [my website's home page](https://www.public.law). Blog post coming soon with details.


## Tests in Production: allocation savings comes from avoiding certain rendering

Here's where the savings come from:

```ruby
= AssetRam::Helper.cache { render 'footer' }
```

My site's footer is static except for the asset links to e.g. social media icons. 


### Production comparison test #1: https://texas.public.law/statutes/tex._fam._code_section_1.001

* 17% fewer allocations (5315 vs. 6414)
* 1,099 allocations saved by simply not re-rendering the footer views.
* 7ms slower


```
2021-09-26T18:14:29.928482+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001] Started GET "/statutes/tex._fam._code_section_1.001" for 172.70.45.212 at 2021-09-26 18:14:29 +0000
2021-09-26T18:14:29.929520+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001] Processing by StatutesController#show as HTML
2021-09-26T18:14:29.929537+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Parameters: {"compilation"=>"statutes", "id"=>"tex._fam._code_section_1.001"}
2021-09-26T18:14:29.933509+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Statute Load (1.4ms)  SELECT "statutes".* FROM "statutes" WHERE (LOWER(citation) = 'tex. fam. code section 1.001')
2021-09-26T18:14:29.933849+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   ↳ app/models/statute.rb:491:in `find_by_cite_case_insensitive'
2021-09-26T18:14:29.937540+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Publication Load (1.1ms)  SELECT "publications".* FROM "publications" WHERE "publications"."jurisdiction_id" = $1 AND "publications"."compilation_slug" = $2 LIMIT $3  [["jurisdiction_id", 206], ["compilation_slug", "statutes"], ["LIMIT", 1]]
2021-09-26T18:14:29.937842+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   ↳ app/controllers/statutes_controller.rb:303:in `publication'
2021-09-26T18:14:29.938542+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendering layout layouts/application.haml
2021-09-26T18:14:29.938577+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendering statutes/leaf_node.haml within layouts/application
2021-09-26T18:14:29.939858+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered statutes/leaf_node.haml within layouts/application (Duration: 1.2ms | Allocations: 149)
2021-09-26T18:14:29.940074+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_description.haml (Duration: 0.0ms | Allocations: 10)
2021-09-26T18:14:29.940669+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_favicon.haml (Duration: 0.4ms | Allocations: 303)
2021-09-26T18:14:29.940924+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_structured_data_website.haml (Duration: 0.0ms | Allocations: 11)
2021-09-26T18:14:29.941028+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_structured_data_organization.haml (Duration: 0.0ms | Allocations: 11)
2021-09-26T18:14:29.941086+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_html_head.haml (Duration: 1.1ms | Allocations: 709)
2021-09-26T18:14:29.942826+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Statute Load (1.1ms)  SELECT "statutes".* FROM "statutes" WHERE "statutes"."id" = $1 LIMIT $2  [["id", 88374639], ["LIMIT", 1]]
2021-09-26T18:14:29.943230+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   ↳ app/presenters/statute_presenter.rb:149:in `parent'
2021-09-26T18:14:29.943596+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_body_tag.erb (Duration: 2.4ms | Allocations: 764)
2021-09-26T18:14:29.944141+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_small_search_form.haml (Duration: 0.2ms | Allocations: 105)
2021-09-26T18:14:29.944440+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_top_nav_bar.haml (Duration: 0.8ms | Allocations: 453)
2021-09-26T18:14:29.944876+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_breadcrumbs.haml (Duration: 0.3ms | Allocations: 397)
2021-09-26T18:14:29.945012+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_devise_alerts.haml (Duration: 0.1ms | Allocations: 25)
2021-09-26T18:14:29.945171+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_citation.haml (Duration: 0.0ms | Allocations: 27)
2021-09-26T18:14:29.945283+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_search_mark_toggle.haml (Duration: 0.0ms | Allocations: 13)
2021-09-26T18:14:29.945498+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_ads.haml (Duration: 0.2ms | Allocations: 76)
2021-09-26T18:14:29.945537+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_right_side_bar.haml (Duration: 0.5ms | Allocations: 296)
2021-09-26T18:14:29.946102+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_footer_for_screen.haml (Duration: 0.4ms | Allocations: 524)
2021-09-26T18:14:29.946243+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_footer_for_print.haml (Duration: 0.1ms | Allocations: 30)
2021-09-26T18:14:29.946328+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_footer.haml (Duration: 0.7ms | Allocations: 677)
2021-09-26T18:14:29.946526+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_analytics.haml (Duration: 0.0ms | Allocations: 14)
2021-09-26T18:14:29.946609+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered application/_closing_body_tag.erb (Duration: 0.0ms | Allocations: 9)
2021-09-26T18:14:29.946646+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001]   Rendered layout layouts/application.haml (Duration: 8.1ms | Allocations: 4132)
2021-09-26T18:14:29.946815+00:00 app[web.1]: [07e1adff-5df8-43d3-aab4-0e1d6b56b001] Completed 200 OK in 17ms (Views: 7.3ms | ActiveRecord: 3.7ms | Elasticsearch: 0.0ms | Allocations: 6414)
```

```
2021-09-26T18:21:26.654003+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1] Started GET "/statutes/tex._fam._code_section_1.001" for 172.70.45.202 at 2021-09-26 18:21:26 +0000
2021-09-26T18:21:26.656935+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1] Processing by StatutesController#show as HTML
2021-09-26T18:21:26.656978+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Parameters: {"compilation"=>"statutes", "id"=>"tex._fam._code_section_1.001"}
2021-09-26T18:21:26.661787+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Statute Load (1.5ms)  SELECT "statutes".* FROM "statutes" WHERE (LOWER(citation) = 'tex. fam. code section 1.001')
2021-09-26T18:21:26.662597+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   ↳ app/models/statute.rb:491:in `find_by_cite_case_insensitive'
2021-09-26T18:21:26.670170+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Publication Load (1.3ms)  SELECT "publications".* FROM "publications" WHERE "publications"."jurisdiction_id" = $1 AND "publications"."compilation_slug" = $2 LIMIT $3  [["jurisdiction_id", 206], ["compilation_slug", "statutes"], ["LIMIT", 1]]
2021-09-26T18:21:26.670808+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   ↳ app/controllers/statutes_controller.rb:303:in `publication'
2021-09-26T18:21:26.671936+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendering layout layouts/application.haml
2021-09-26T18:21:26.671990+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendering statutes/leaf_node.haml within layouts/application
2021-09-26T18:21:26.676444+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered statutes/leaf_node.haml within layouts/application (Duration: 1.8ms | Allocations: 149)
2021-09-26T18:21:26.676446+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_description.haml (Duration: 0.1ms | Allocations: 10)
2021-09-26T18:21:26.676446+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_favicon.haml (Duration: 0.5ms | Allocations: 247)
2021-09-26T18:21:26.676446+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_structured_data_website.haml (Duration: 0.0ms | Allocations: 11)
2021-09-26T18:21:26.676447+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_structured_data_organization.haml (Duration: 0.0ms | Allocations: 11)
2021-09-26T18:21:26.676447+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_html_head.haml (Duration: 1.4ms | Allocations: 591)
2021-09-26T18:21:26.677699+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Statute Load (1.3ms)  SELECT "statutes".* FROM "statutes" WHERE "statutes"."id" = $1 LIMIT $2  [["id", 88374639], ["LIMIT", 1]]
2021-09-26T18:21:26.678321+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   ↳ app/presenters/statute_presenter.rb:149:in `parent'
2021-09-26T18:21:26.678955+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_body_tag.erb (Duration: 3.4ms | Allocations: 764)
2021-09-26T18:21:26.679660+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_top_nav_bar.haml (Duration: 0.6ms | Allocations: 264)
2021-09-26T18:21:26.680105+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_breadcrumbs.haml (Duration: 0.3ms | Allocations: 397)
2021-09-26T18:21:26.680279+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_devise_alerts.haml (Duration: 0.1ms | Allocations: 25)
2021-09-26T18:21:26.680500+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_citation.haml (Duration: 0.1ms | Allocations: 28)
2021-09-26T18:21:26.680632+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_search_mark_toggle.haml (Duration: 0.0ms | Allocations: 13)
2021-09-26T18:21:26.680935+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_ads.haml (Duration: 0.2ms | Allocations: 77)
2021-09-26T18:21:26.680981+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_right_side_bar.haml (Duration: 0.6ms | Allocations: 298)
2021-09-26T18:21:26.681199+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_analytics.haml (Duration: 0.1ms | Allocations: 14)
2021-09-26T18:21:26.681307+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered application/_closing_body_tag.erb (Duration: 0.0ms | Allocations: 9)
2021-09-26T18:21:26.681357+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1]   Rendered layout layouts/application.haml (Duration: 9.4ms | Allocations: 3040)
2021-09-26T18:21:26.681614+00:00 app[web.1]: [2058c55d-fc7f-4914-ac65-94a7862f1df1] Completed 200 OK in 24ms (Views: 8.6ms | ActiveRecord: 4.1ms | Elasticsearch: 0.0ms | Allocations: 5315)
```


## Usage

Wrap every asset helper call with `#cache`, like this:

### Before

```ruby
<%= favicon_link_tag('favicon/favicon.ico', rel: 'icon') %>
```

### After

```ruby
<%= AssetRam::Helper.cache { favicon_link_tag('favicon/favicon.ico', rel: 'icon') } %>
```

After booting up, a message like this will appear _once_ in the log when the asset link
is generated. It shows the full cache key so we can see what it's caching. This is the line
of code that, without AssetRam, would be exectued on every request.

```
Caching ["/Users/robb/src/PublicLaw/public-law-website/app/views/application/_favicon.haml", 8]
```

I use it in my footer for social icons as well: (HAML syntax)

```ruby
= link_to asset.cache { image_tag("social/instagram-logo.svg", alt: 'Instagram', loading: 'lazy', decoding: 'async') },    "https://www.instagram.com/law.is.code/"
= link_to asset.cache { image_tag("social/facebook-logo-button.svg", alt: 'Facebook', loading: 'lazy', decoding: 'async') }, "https://www.facebook.com/PublicDotLaw"
= link_to asset.cache { image_tag("social/twitter-logo-button.svg", alt: 'Twitter', loading: 'lazy', decoding: 'async') },   "https://twitter.com/law_is_code"
= link_to asset.cache { image_tag("social/github-logo.svg", alt: 'Our GitHub Page', loading: 'lazy', decoding: 'async') },   "https://www.github.com/public-law/"
```




### In some cases, the cache key can't be inferred.

RamCache creates the cache key automatically using the view source filename and line number.
This works for most uses. 

Some of my app's views are an exception, however. It's multi-tenant and the views serve content
for several sub-domains. And so the call to `#cache` allows extra key info to be passed.
In my HTML HEAD view, I have a `site` variable for choosing the CSS file for the domain:

```ruby
<%= AssetRam::Helper.cache(key: site) { stylesheet_link_tag("themes/#{site}", media: nil) } %>
```

## Background: I was looking for ways to reduce allocations in my Rails app

In an effort to help my app run in a small 512MB virtual server, I looked through every view
invocation in the logs. After I optimized a bunch of my code, I realized that the asset helpers
create a relatively large amount of objects. The code is pretty complex too implying some amount
of CPU overhead. Moreover, this work is done over **on every request**.

These asset fingerprints are potentially re-generated on every deploy. So they can't be stored in
the usual Rails cache. I realized that storing the computed paths in a simple hash (in RAM only)
would be fast and never return stale data: The RAM cache goes away on a deploy/restart, which is
when asset fingerprints could change.

And so one-by-one I started storing the computed asset paths in a hash, and saw pretty dramatic results.

## How it works: Block-based code executed in the view's context and inferred cache keys

Rails has some magic around when the asset helpers are able to create the fingerprint path. I found
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
