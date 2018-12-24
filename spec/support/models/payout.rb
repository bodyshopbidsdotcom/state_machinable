class Payout < ActiveRecord::Base
  include StateMachinable::Model

  has_many :payout_transitions
  validates :field1, :inclusion => [nil, 'field1']
end
