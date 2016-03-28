![Waterfall Logo](http://apneadiving.github.io/images/waterfall_logo.png)
[![Code Climate](https://codeclimate.com/github/apneadiving/waterfall/badges/gpa.svg)](https://codeclimate.com/github/apneadiving/waterfall)
[![Test Coverage](https://codeclimate.com/github/apneadiving/waterfall/badges/coverage.svg)](https://codeclimate.com/github/apneadiving/waterfall/coverage)
[![Build Status](https://travis-ci.org/apneadiving/waterfall.svg?branch=master)](https://travis-ci.org/apneadiving/waterfall)
#### Goal

Be able to chain ruby commands, and treat them like a flow.

General presentation slides can [be found here](https://slides.com/apneadiving/code-ruby-like-you-build-legos).

Check [the slides here](https://slides.com/apneadiving/handling-error-in-ruby-rails) for a refactoring example.


#### Basic example

```ruby
Wf.new
  .when_falsy { @user.update(user_params) }
    .dam { @user.errors }
  .chain { render json: @user }
  .on_dam { |errors| render json: { errors: errors.full_messages }, status: 422 }
```

When logic is complicated, waterfalls show their true power and let you write intention revealing code. Above all they excel at chaining services.

#### Rationale
Coding is all about writing a flow of commands.

Generally you basically go on, unless something wrong happens. Whenever this happens you have to halt the flow and send feedback to the user.

When conditions stack up, readability decreases.

One way to solve it is to create abstractions to wrap your business logic (service objects or the like). There some questions arise:
* what should a good service return?
* how to handle errors?
* how to call a service within a service?
* how to chain services / commands

Those topics are discussed in [the slides here](https://slides.com/apneadiving/service-objects-waterfall-rails).


## Wf object

The `Wf` class just includes the `Waterfall` module. It makes it easy to create standalone waterfalls mostly to chain actions or to chain services including `Waterfall` or returning a `Wf` object.

Basically `chain` statements are executed in the order they appear. But if ever the waterfall is dammed, they are skipped.

If a main waterfall chains another waterfall and the child waterfall is dammed, the main waterfall would be dammed.

The point is to be able to be able to chain an expected set of actions whenever everything works fine. And to be able to quickly stop and get the errors back whenever something wrong happens.

## Installation

For installation, in your gemfile:

    gem 'waterfall'
    
then `bundle` as usual.

## Waterfall mixin

### Overview

The following are equivalent:
```ruby
# 1
Wf.new.chain{ 1 + 1 }

# 2
class MyService
  include Waterfall

  def call
    self.chain{ 1 + 1 }
  end
end

MyService.new.call
```

This illustrates one convention classes including the mixin should obey: respond to `call`

### Outputs

Each waterfall has its own `outflow` and `error_pool`.

`outflow` is an Openstruct so you can get/set its property like a hash or like a standard object.

For the `error_pool`, its up to you. But using Rails, I usually `include ActiveModel::Validations` in my services.

Thus you:

* have a standard way to deal with errors
* can deal with multiple errors
* support I18n out of the box
* can use your model errors out of the box

## Illustration of chaining
Doing
```ruby
 Wf.new
   .chain(foo: :bar) { Wf.new.chain(:bar){ 1 } }
```

is the same as doing:

```ruby
 Wf.new
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

## Predicates

### chain(name_or_mapping = nil, &block) | block signature: (outflow, waterfall)

Chain is the main predicate, what it does depends on what the block returns
```ruby
 # main waterfall
 Wf.new
   .chain(foo: :bar) do
     # child waterfall
     Wf.new.chain(:bar){ 1 }.chain(:baz){ 2 }.chain{ 3 }
   end
```
##### when block doesn't return a waterfall

The child waterfall would have the following outflow: `{ bar: 1, baz: 2 }`

This illustrates that when the block returns a value which is not a waterfall, it stores the returned value of the block inside the `name_or_mapping` key of the `outflow` or doesn't store it if `name_or_mapping` is `nil`.

Be aware those are equivalent:

```ruby
Wf.new.chain(:foo) { 1 }
Wf.new.chain{|outflow| outflow[:foo] = 1 }
Wf.new.chain{|outflow| outflow.foo = 1 }
Wf.new.chain{|outflow, waterfall| waterfall.update_outflow(:foo, 1) }
Wf.new.chain{|outflow, waterfall| waterfall.outflow.foo = 1 }
```
##### when block returns a waterfall

The main waterfall would have the following outflow: `{ foo: 1 }`

The main waterfall above receives the child waterfall as a return value of its `chain` block.
All waterfalls have independent outflows.

If `name_or_mapping` is `nil`, the main waterfall's `outflow` wouldnt be affected by its child (but if the child is dammed, the parent will be dammed).

If `name_or_mapping` is a `hash`, the format must be read as `{ name_in_parent_waterfall: :name_from_child_waterfall}`. In the above example, the child returned an `outflow` with a `bar` key which has be renamed as `foo` in the main one.

It may look useless, because most of the time you may not rename, but... It makes things clear. You know exactly what you expect and you know exactly that you dont expect the rest the child may provide.

### when_falsy(&block) | block signature: (error_pool, waterfall)

This predicate must ***always*** be used followed with `dam` like:

```ruby
Wf.new
  .chain(:foo) { 1 }
  .when_falsy { true }
   .dam { "this wouldnt be executed"  }
  .when_falsy { false }
   .dam { "errrrr"  }
  .chain(:bar) { 2 }
  .on_dam {|error_pool| puts error_pool  }
```

If the block returns a falsy value, it executes the `dam` block, which will store the returned value in the `error_pool`.

Once the waterfall is dammed, all following `chain` blocks are skipped (wont be executed). And all the following `on_dam` block would be executed.

As a result the example above would return a waterfall object having its `outflow` equal to `{ foo: 1 }`. Remember: it has been dammed before `bar` would have been set.

Its `error_pool` would be `"errrrr"` and it would be `puts` as a result of the `on_dam`

Be aware those are equivalent:

```ruby
Wf.new.when_falsy{ false }.dam{ 'errrr' }
Wf.new.chain{ |outflow, waterfall| waterfall.dam('errrr') unless false }
```

### when_truthy(&block) | block signature: (error_pool, waterfall)

Behaves the same as `when_falsy` except it dams when its return value is truthy

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
Wf.new
  .chain { MyWaterfall.new }
```
instead of
```ruby
Wf.new
  .chain { MyWaterfall.new.call }
```
Both are the same: if a block returns a waterfall which was not executed, it will execute it (hence the `call` convention)

### on_dam(&block) | block signature: (error_pool, outflow, waterfall)

Its block is executed whenever the waterfall is dammed, skipped otherwise.

```ruby
Wf.new
  .when_falsy { false }
  .on_dam {|error_pool, outflow, waterfall| puts error_pool  }
```

## Error propagation

Whenever a a waterfall is dammed, all the following chains are skipped.

* all the following chains are skipped
* all `on_dam` blocks are executed

## Testing a Waterfall service

Say I have this service:
```ruby
class AuthenticateUser
  include Waterfall
  include ActiveModel::Validations

  validates :user, presence: true
  attr_reader :user

  def initialize(email, password)
    @email, @password = email, @password
  end

  def call
    self
      .chain { @user = User.authenticate(@email, @password) }
      .when_falsy { valid? }
         .dam { errors }
      .chain(:user) { user }
  end
end
```
I could spec it this way:
```ruby
describe AuthenticateUser do
  let(:email)    { 'email@email.com' }
  let(:password) { 'password' }
  subject(:service) { AuthenticateUser.new(email, password).call }

  context "when given valid credentials" do
    let(:user) { double(:user) }

    before do
      allow(User).to receive(:authenticate).with(email, password).and_return(user)
    end

    it "succeeds" do
      expect(service.dammed?).to be false
    end

    it "provides the user" do
      expect(service.outflow.user).to eq(user)
    end
  end

  context "when given invalid credentials" do
    before do
      allow(User).to receive(:authenticate).with(email, password).and_return(nil)
    end

    it "fails" do
      expect(service.dammed?).to be true
    end

    it "provides a failure message" do
      expect(service.error_pool).to be_present
    end
  end
end
```
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
    @email, @password = email, @password
  end

  def call
    with_transaction do 
      self
        .chain { @user = User.authenticate(@email, @password) }
        .when_falsy { valid? }
          .dam { errors }
        .chain(:user) { user }
    end
  end
end
```
The huge benefit is that if you call services from services, everything will be rolled back.

Examples
=========
Check the [wiki for other examples](https://github.com/apneadiving/waterfall/wiki).

Thanks
=========
Huge thanks to [laxrph10](https://github.com/laxrph10) for the help during infinite naming brainstorming.
