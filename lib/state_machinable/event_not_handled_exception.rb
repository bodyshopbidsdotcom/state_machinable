module StateMachinable
  class EventNotHandledException < StandardError
    def initialize(event:, state:)
      super("EVENT '#{event}' not implemented for state '#{state}'")
    end
  end
end
