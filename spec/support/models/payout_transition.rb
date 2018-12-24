class PayoutTransition < ActiveRecord::Base
  include Statesman::Adapters::ActiveRecordTransition

  belongs_to :payout, :inverse_of => :payout_transitions

  after_destroy :update_most_recent, :if => :most_recent?

  private

  def update_most_recent
    last_transition = payout.payout_transitions.order(:sort_key).last
    return unless last_transition.present?
    last_transition.update_column(:most_recent, true)
  end
end
