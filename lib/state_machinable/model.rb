module StateMachinable
  module Model
    extend ActiveSupport::Concern

    class_methods do
      def state_machine_class
        "#{self}StateMachine".constantize
      end

      def transition_class
        "#{self}Transition".constantize
      end
    end

    included do
      before_save :send_ev_before_save, :if => Proc.new { |obj| obj.changed? }
      after_save :send_ev_after_save, :if => Proc.new { |obj| !obj.id_changed? && obj.changed? }
      after_save :transition_to_initial_state, :if => Proc.new { |obj| obj.id_changed? }
      delegate :can_transition_to?, :transition_to!, :transition_to, :to => :state_machine

      def state_machine
        @state_machine ||= self.class.state_machine_class.new(self, :transition_class => self.class.transition_class)
      end

      def send_ev_before_save
        self.state_machine.send('ev_before_save')
      end

      def send_ev_after_save
        self.state_machine.send('ev_after_save')
      end

      private def transition_to_initial_state
        if !self.respond_to?(:skip_state_machine?) || !self.skip_state_machine?
          self.transition_to!(self.state_machine.class.successors['initial'].first)
        end
      end
    end
  end
end
