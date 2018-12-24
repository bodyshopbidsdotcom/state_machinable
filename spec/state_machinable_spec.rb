require "spec_helper"

RSpec.describe StateMachinable do
  it "has a version number" do
    expect(StateMachinable::VERSION).not_to be nil
  end

  it 'defines state_machine_class' do
    expect(Payout.state_machine_class).to eq(PayoutStateMachine)
  end

  it 'defines transition_class' do
    expect(Payout.transition_class).to eq(PayoutTransition)
  end

  it 'transitions to the initial state' do
    payout = Payout.new

    expect { payout.save! }
      .to change { PayoutTransition.count }.by(1)
      .and change { Payout.count }.by(1)
      .and change { payout.payout_transitions.count }.by(1)
      .and change { payout.current_state }.from(nil).to('awaiting_approval')
  end

  it 'calls enter on transition by event' do
    payout = Payout.create!
    payout.state_machine.event_payout_approved!
    expect(PayoutStateMachine::Sent).to receive(:enter).with(payout).and_call_original

    expect { payout.state_machine.event_sent! }
      .to change { payout.reload.sent_at.nil? }.from(true).to(false)
  end

  it 'ignores current_state update in pre_enter_updates_to_do' do
    payout = Payout.create!

    expect { payout.state_machine.event_payout_approved! }
      .to change { payout.reload.current_state }.from('awaiting_approval').to('ready_to_send')
  end

  it 'passes the payout to pre_enter_updates_to_do' do
    payout = Payout.create!(:field1 => 'field1')

    expect { payout.state_machine.event_payout_approved! }
      .to change { payout.reload.field2 }.from(nil).to('field1')
  end

  it 'crashes if the event does not exist' do
    payout = Payout.create!

    expect { payout.state_machine.event_doesnt_exist }.to raise_error(NoMethodError)
  end

  it 'does not crash if event called without ! and the state doesnt implement it' do
    payout = Payout.create!

    expect { payout.state_machine.event_sent }.to_not raise_error
  end

  it 'crashes if event called with ! and the state doesnt implement it' do
    payout = Payout.create!

    expect { payout.state_machine.event_sent! }.to raise_error(StateMachinable::EventNotHandledException)
  end

  it 'calls and updates the object with the values returned by pre_enter_updates_to_do' do
    payout = Payout.create!

    expect { payout.state_machine.event_cancelled! }
      .to change { payout.reload.current_state }.from('awaiting_approval').to('cancelled')
      .and change { payout.reload.cancelled_at.nil? }.from(true).to(false)
  end

  it 'does not silently fail' do
    payout = Payout.create!(:field3 => 'Random invalid string for field1')
    payout.state_machine.event_payout_approved!
    payout.state_machine.event_sent!

    expect { payout.state_machine.event_failed! }
      .to raise_error(ActiveRecord::RecordInvalid)

    expect(payout.reload.current_state).to eq('sent')
  end
end
