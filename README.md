# StateMachinable

Adds state machine functionality to `statesman`

## Installation

Add these lines to your application's Gemfile:

```ruby
gem 'state_machinable'
gem 'statesman'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install statesman
    $ gem install state_machinable

## Setup

Generate the transitions for a model, e.g. `Order`

    $ rails g migration CreateOrderTransitions

The migration will look very similar to if you had generated it with Statesman, but with a `current_state` added
    
    `rails g statesman:active_record_transition Order OrderTransition`

```ruby
class CreateOrderTransitions < ActiveRecord::Migration
  def change
    add_column :orders, :current_state, :string # <- ADD THIS LINE
    create_table :order_transitions do |t|
      t.string :to_state, null: false
      t.text :metadata
      t.integer :sort_key, null: false
      t.integer :order_id, null: false
      t.boolean :most_recent
      t.timestamps null: false
    end

    add_index(:order_transitions, [:order_id, :sort_key], unique: true, name: "index_order_transitions_parent_sort")
    add_index(:order_transitions, [:order_id, :most_recent], unique: true, name: "index_order_transitions_parent_most_recent")
  end
end
```

In your model, include this library and transitions:

```ruby
class Order < ActiveRecord::Base
    include StateMachinable::Model
    has_many :order_transitions, :dependent => :destroy
```

Then set up your state transitions:
```ruby
# app/state_machines/order_state_machine.rb

class OrderStateMachine
  include StateMachinable::Base

  # define your states
  state :open
  state :processing
  state :shipped
  state :delivered
  state :cancelled

  # define transitions
  transition :from => :initial, :to => :open
  transition :from => :open, :to => [:processing, :cancelled]
  transition :from => :processing, :to => [:shipped, :cancelled]
  transition :from => :shipped, :to => [:delivered]

  # define events that may occur
  EVENTS = [
    :event_processing,
    :event_shipped,
    :event_cancelled,
    :event_delivered
  ].freeze

  # define a class for each state, with methods for event that may occur within that state
  class Open
    def self.event_processing(order)
      order.transition_to!(:processing)
      # TODO: send order confirmation email to customer
    end
    def self.event_cancelled(order)
      order.transition_to!(:cancelled)
      # ...
    end
  end
  
  class Shipped
    def self.event_delivered(order)
      order.transition_to!(:delivered)
      # ...
    end
  end
end

```

There are also hooks for the state changes that could be used instead of duplicating logic in multiple events that transition to the same state

```ruby
class Cancelled
  def self.enter(order)
    # TODO: send email to customer that order is cancelled
  end
end

```

## Usage
When you want to transition from one state to another, call an event:

```ruby
order.state_machine.event_shipped
```

You may want to use a transaction around the event to ensure that both the current_state and transitions are committed, or to prevent invalid states

```ruby
ActiveRecord::Base.transaction do
  # without a transaction here then an invoice could be created without the order's state succeeding in transitioning to shipped
  Order.create_invoice_for_order!(order)
  order.state_machine.event_shipped
end
```

You can check the model's state with `#current_state`

```ruby
order.current_state
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bodyshopbidsdotcom/state_machinable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
