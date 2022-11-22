class PayoutStateMachine
  include StateMachinable::Base

  state :awaiting_approval
  state :ready_to_send
  state :cancelled
  state :sent
  state :failed

  transition :from => :initial, :to => :awaiting_approval
  transition :from => :awaiting_approval, :to => [:cancelled, :ready_to_send]
  transition :from => :ready_to_send, :to => [:cancelled, :sent]
  transition :from => :sent, :to => :failed

  EVENTS = [
    :event_payout_approved,
    :event_cancelled,
    :event_sent,
    :event_failed
  ].freeze

  class AwaitingApproval
    def self.event_payout_approved(payout)
      payout.state_machine.transition_to!(:ready_to_send)
    end

    def self.event_cancelled(payout)
      payout.state_machine.transition_to!(:cancelled)
    end
  end

  class ReadyToSend
    def self.pre_enter_updates_to_do(payout)
      { :current_state => 'some_random_state', :field2 => payout.field1 }
    end

    def self.event_sent(payout)
      payout.state_machine.transition_to!(:sent)
    end
  end

  class Cancelled
    def self.pre_enter_updates_to_do(payout)
      { :cancelled_at => Time.now }
    end
  end

  class Sent
    def self.enter(payout)
      payout.update!(:sent_at => Time.now)
    end

    def self.event_failed(payout)
      payout.state_machine.transition_to!(:failed)
    end
  end

  class Failed
    def self.pre_enter_updates_to_do(payout)
      { :field1 => payout.field3 }
    end
  end
end
