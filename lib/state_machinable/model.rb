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
      after_save :transition_to_initial_state, :if => Proc.new { |obj| obj.saved_change_to_id? }
      delegate :can_transition_to?, :transition_to!, :transition_to, :to => :state_machine

      def state_machine
        @state_machine ||= self.class.state_machine_class.new(self, :transition_class => self.class.transition_class)
      end

      private def transition_to_initial_state
        initial_state = self.state_machine.class.successors['initial'].first
        if (!self.respond_to?(:skip_state_machine?) || !self.skip_state_machine?) && (self.current_state != initial_state)
          self.transition_to!(self.state_machine.class.successors['initial'].first)
        end
      end
    end
  end
end
