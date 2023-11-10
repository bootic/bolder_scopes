# Bolder::Scopes

Hyerarchical scopes definition and validation for Bolder apps and APIs.

## Installation

```
gem 'bolder_scopes', require: 'bolder/scopes'
```

## Scope hierarchies

Scopes are permission trees.
For example, the scope `all.users.create` represents the following structure:

```
all
  users
    create
```

A request's token scope is compared with a given endpoint's token to check access permissions, from left to right.

* `all` has access to `all`
* `all` has access to `all.users`
* `all.users` has access to `all.users.create`
* `all.accounts` does NOT have access to `all.users`
* `all.accounts` does NOT have access to `all.users.create`

_Wildcard_ scopes are possible using the special character `*` as one or more segments in a scope.
For example:

* `all.*.create` has access to `all.accounts.create` or `all.photos.create`
* `all.*.create` has access to `all.accounts.*`
* `all.*.create.*` does not have access to `all.accounts.create` (because it's more specific).

## Usage in a web request handler

```ruby
def index
  request_scope = access_token.scope # ex. bolder.accounts.123.shops.*.read
  resource_scope = Bolder::Scopes.wrap(['bolder', 'accounts', current_account.id, 'shops', 'read'].join('.'))

  if request_scope >= resource_scope
    render
  else
    render :unauthorized, status: 403
  end
end
```

## Pre-defined scope trees

Defining scopes as strings can be error prone (easy to make typos or get the hierarchy wrong!).

The `Bolder::Scopes::Tree` utility can be helpful to define all possible scope hierarchies in a single place.

```ruby
SCOPES = Bolder::Scopes::Tree.new('all') do |all|
  all.users.update
  all.users.read
  all.users.create
  all.orders.read
end
```

The scope tree will expose all defined hierarchies

```ruby
SCOPES.all.users # 'all.users'
SCOPES.all.users.create # 'all.users.create'
```

... But not invalid hierarchies.

```ruby
SCOPES.all.users.orders # => raises Bolder::Scopes::Scope::InvalidScopHierarchyError
```

Wilcards work too

```ruby
SCOPES.all.*.read # 'all.*.read`
```

Note that wildcards only allow sub-scopes that are shared by all children.

```ruby
SCOPES.all.*.read # Ok
SCOPES.all.*.update # raises InvalidScopHierarchyError because not all children of `all.*` support `update`
```

Hierarchies can also be defined using the > operator:
This can help avoid typos.

```ruby
SCOPES = Bolder::Scopes::Tree.new('bolder') do |bolder|
  api = 'api'
  products = 'products'
  orders = 'orders'
  own = 'own'
  all = 'all'
  read = 'read'

  bolder > api > products > own > read
  bolder > api > products > all > read
  bolder > api > orders > own > read
end
```

Block notation can be used where it makes sense:

```ruby
SCOPES = Bolder::Scopes::Tree.new('bolder') do |bolder|
  bolder.api.products do |n|
    n.own do |n|
      n.read
      n.write
      n > 'list' # use `>` to append variables or constants
    end
  end
end
```

Block notation also works without explicit node argument (but can't access outer variables):

```ruby
SCOPES = Bolder::Scopes::Tree.new('bolder') do
  api.products do
    own do
      read
      write
    end
    all do
      read
    end
  end
end
```

Use `_any` to define segments that can be anything:

```ruby
SCOPES = Bolder::Scopes::Tree.new('bolder') do |bolder|
  bolder.api.products._any.read
end
```

`_any` takes an optional list of allowed values, in which case it has "any of" semantics.
Values are matched with `#===` operator, so they can be regular expressions.
If no values are given, `_any` has "anything" semantics.
`_any` can be used to define a catch-all scope:

```ruby
SCOPES = Bolder::Scopes::Tree.new('bolder') do |bolder|
 bolder.api do |s|
   s.products do |s|
     s._any('my_products', /^\d+$/) do |s| # matches 'my_products' or any number-like string
       s.read
     end
  end
end
```

With the above, the following scopes are allowed, using parenthesis notation to allow numbers and multiple values

```ruby
bolder.api.products.(123).read # 'bolder.api.products.123.read'
bolder.api.products.(1, 2, 3).read # 'bolder.api.products.(1,2,3).read'
bolder.api.products.('my_products').read # 'bolder.api.products.my_products.read'
bolder.api.products.my_products.read # works too
```

## Scope maps

`Bolder::Scopes::Map` can be used to expand one scope to others.

```ruby
map = Bolder::Scopes::Map.new('read' => ['read.users'])
map.map('read') # => ['read.users']
map.map('read:users') # => ['read.users']
```

Use `Map#expand` to include the original scope in the resulting list.

```ruby
map = Bolder::Scopes::Map.new('read' => 'read.users')
map.expand('read') # => Scopes['read', 'read.users']
```

Scope trees also work with scope maps.

```ruby
map = Bolder::Scopes::Map.new(
  SCOPES.admin => [SCOPES.api.products.own, SCOPES.api.orders.own, SCOPES.api.all.read],
  'god' => [SCOPES.api]
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bolder/bolder_scopes.
