class Payout < ActiveRecord::Base
  include StateMachinable::Model

  has_many :payout_transitions
end
