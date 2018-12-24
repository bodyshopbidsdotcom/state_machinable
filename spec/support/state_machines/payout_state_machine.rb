class PayoutStateMachine
  include StateMachinable::Base

  state :awaiting_approval
  state :ready_to_send
  state :cancelled
  state :sent

  transition :from => :initial, :to => :awaiting_approval
  transition :from => :awaiting_approval, :to => [:cancelled, :ready_to_send]
  transition :from => :ready_to_send, :to => [:cancelled, :sent]

  EVENTS = [
    :event_payout_approved,
    :event_sent
  ].freeze

  class AwaitingApproval
    def self.event_payout_approved(payout)
      payout.state_machine.transition_to!(:ready_to_send)
    end
  end

  class ReadyToSend
    def self.event_sent(payout)
      payout.state_machine.transition_to!(:sent)
    end
  end

  class Cancelled
  end

  class Sent
    def self.enter(payout)
      payout.update!(:sent_at => Time.now)
    end
  end
end
