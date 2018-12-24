module StateMachinable
  module Base
    extend ActiveSupport::Concern

    class_methods do
      def state_class(state)
        "#{self}::#{state.classify}".constantize
      rescue NameError
        nil
      end
    end

    included do
      include Statesman::Machine

      state :initial, :initial => true

      before_transition do |obj, _transition|
        state_class = obj.state_machine.class.state_class(obj.state_machine.current_state)
        if state_class.present? && state_class.respond_to?(:exit)
          state_class.exit(obj)
        end
      end

      after_transition do |obj, transition|
        state_class = obj.state_machine.class.state_class(transition.to_state)
        update_hash = {}

        if state_class.present? && state_class.respond_to?(:pre_enter_updates_to_do)
          update_hash.merge!(state_class.pre_enter_updates_to_do(obj))
        end

        obj.update(update_hash.merge!(:current_state => transition.to_state))

        if state_class.present? && state_class.respond_to?(:enter)
          state_class.enter(obj)
        end
      end

      def method_missing(name, *args, &block)
        begin
          events = "#{self.class}::EVENTS".constantize.dup
        rescue NameError
          events = []
        end

        clean_name = name.to_s.chomp('!').to_sym

        if events.include?(clean_name)
          state_class = self.class.state_class(self.current_state)
          if state_class.present? && state_class.respond_to?(clean_name)
            state_class.send(clean_name, self.object, *args)
          else
            if name.to_s.last == '!'
              raise StateMachinable::EventNotHandledException.new(:event => clean_name, :state => self.current_state)
            else
              nil
            end
          end
        else
          super
        end
      end
    end
  end
end
