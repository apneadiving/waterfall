[![Code Climate](https://codeclimate.com/github/apneadiving/waterfall/badges/gpa.svg)](https://codeclimate.com/github/apneadiving/waterfall)
[![Test Coverage](https://codeclimate.com/github/apneadiving/waterfall/badges/coverage.svg)](https://codeclimate.com/github/apneadiving/waterfall/coverage)
[![Build Status](https://travis-ci.org/apneadiving/waterfall.svg?branch=master)](https://travis-ci.org/apneadiving/waterfall)
[![Gem Version](https://badge.fury.io/rb/waterfall.svg)](https://badge.fury.io/rb/waterfall)
#### Goal

Chain ruby commands, and treat them like a flow, which provides a new approach to application control flow.

When logic is complicated, waterfalls show their true power and let you write intention revealing code. Above all they excel at chaining services.

#### Material
<a href="https://leanpub.com/the-unhappy-path"> <img align="left" width="80" height="116" src="https://apneadiving.github.io/images/unhappy-path.png"> </a>
Upcoming book about failure handling management, leveraging the gem: [The Unhappy path](https://leanpub.com/the-unhappy-path)

General presentation blog post there: [Chain services objects like a boss](https://medium.com/p/chain-service-objects-like-a-boss-35d0b83606ab).

Reach me [@apneadiving](https://twitter.com/apneadiving)


#### Overview

A waterfall object has its own flow of commands, you can chain your commands and if something wrong happens, you dam the flow which bypasses the rest of the commands.

Here is a basic representation:
- green, the flow goes on, `chain` by `chain`
- red its bypassed and only `on_dam` blocks are executed.

![Waterfall Principle](https://apneadiving.github.io/images/waterfall_principle.png)

#### Example

```ruby
class FetchUser
  include Waterfall

  def initialize(user_id)
    @user_id = user_id
  end

  def call
    chain { @response = HTTParty.get("https://jsonplaceholder.typicode.com/users/#{@user_id}") }
    when_falsy { @response.success? }
      .dam { "Error status #{@response.code}" }
    chain(:user) { @response.body }
  end
end
```

and call / chain:

```ruby
Flow.new
    .chain(user1: :user) { FetchUser.new(1) }
    .chain(user2: :user) { FetchUser.new(2) }
    .chain  {|outflow| puts(outflow.user1, outflow.user2)  } # report success
    .on_dam {|error|   puts(error)      }                    # report error
```

Which works like:

![Waterfall Logo](http://apneadiving.github.io/images/waterfall_full_example.png)

## Installation

For installation, in your gemfile:

    gem 'waterfall'

then `bundle` as usual.

## Waterfall mixin

### Outputs

Each waterfall has its own `outflow` and `error_pool`.

`outflow` is an Openstruct so you can get/set its property like a hash or like a standard object.

### Wiki
Wiki contains many details, please check appropriate pages:

- [Predicates](https://github.com/apneadiving/waterfall/wiki/Predicates)
- [Wf Object](https://github.com/apneadiving/waterfall/wiki/Wf-object)
- [Testing](https://github.com/apneadiving/waterfall/wiki/Testing)

### Koans (!)
You can try and exercise your understanding of Waterfall using the [Koans here](https://github.com/apneadiving/waterfall_koans)

## Illustration of chaining
Doing
```ruby
Flow.new
    .chain(foo: :bar) { Flow.new.chain(:bar){ 1 } }
```

is the same as doing:

```ruby
Flow.new
    .chain do |outflow, parent_waterfall|
      unless parent_waterfall.dammed?
        child = Wf.new.chain(:bar){ 1 }
        if child.dammed?
          parent_waterfall.dam(child.error_pool)
        else
          parent_waterfall.ouflow.foo = child.outflow.bar
        end
      end
    end
```

Hopefully you better get the chaining power this way.


## Syntactic sugar
Given:
```ruby
class MyWaterfall
  include Waterfall
  def call
    self.chain { 1 }
  end
end
```
You may have noticed that I usually write:

```ruby
Flow.new
    .chain { MyWaterfall.new }
```
instead of
```ruby
Flow.new
    .chain { MyWaterfall.new.call }
```
Both are the same: if a block returns a waterfall which was not executed, it will execute it (hence the `call` convention)


Syntax advice
=========
```ruby
# this is valid
self
  .chain { Service1.new }
  .chain { Service2.new }

# this is equivalent
self.chain { Service1.new }
self.chain { Service2.new }

# this is equivalent too
chain { Service1.new }
chain { Service2.new }

# this is invalid Ruby due to the extra line
self
  .chain { Service1.new }

  .chain { Service2.new }
```

Tips
=========
### Error pool
For the error_pool, its up to you. But using Rails, I usually include ActiveModel::Validations in my services.

Thus you:

- have a standard way to deal with errors
- can deal with multiple errors
- support I18n out of the box
- can use your model errors out of the box

### Conditional Flow
In a service, there is one and single flow, so if you need conditionals to branch off, you can do:
```ruby
self.chain { Service1.new }

if foo?
  self.chain { Service2.new }
else
  self.chain { Service3.new }
end
```

### Rails and transactions
I'm used to wrap every single object involving database interactions within transactions, so it can be rolled back on error.
Here is my usual setup:
```ruby
module Waterfall
  extend ActiveSupport::Concern

  class Rollback < StandardError; end

  def with_transaction(&block)
    ActiveRecord::Base.transaction(requires_new: true) do
      yield
      on_dam do
        raise Waterfall::Rollback
      end
    end
  rescue Waterfall::Rollback
    self
  end
end
```

And to use it:
```ruby
class AuthenticateUser
  include Waterfall
  include ActiveModel::Validations

  validates :user, presence: true
  attr_reader :user

  def initialize(email, password)
    @email, @password = email, password
  end

  def call
    with_transaction do
      chain { @user = User.authenticate(@email, @password) }
      when_falsy { valid? }
        .dam { errors }
      chain(:user) { user }
    end
  end
end
```
The huge benefit is that if you call services from services, everything will be rolled back.

### FYI

`Flow` is just an alias for the `Wf` class, so just use the one you prefer :)

Examples / Presentations
========================
- Check the [wiki for other examples](https://github.com/apneadiving/waterfall/wiki/Refactoring-examples).
- [Structure and chain your POROs](http://slides.com/apneadiving/structure-and-chain-your-poros).
- [Service objects implementations](https://slides.com/apneadiving/service-objects-waterfall-rails).
- [Handling error in Rails](https://slides.com/apneadiving/handling-error-in-ruby-rails).

Thanks
=========
Huge thanks to [robhorrigan](https://github.com/robhorrigan) for the help during infinite naming brainstorming.
