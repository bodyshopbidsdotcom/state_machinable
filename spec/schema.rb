ActiveRecord::Schema.define do
  self.verbose = false

  create_table :payouts, :force => :cascade do |t|
    t.integer :amount_in_cents
    t.string :current_state
    t.string :payee_name
    t.string :field1
    t.string :field2
    t.string :field3
    t.datetime :sent_at
    t.datetime :cancelled_at
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end

  create_table :payout_transitions, :force => :cascade do |t|
    t.string :to_state,   null: false
    t.text :metadata
    t.integer :sort_key, null: false
    t.integer :payout_id, null: false
    t.boolean :most_recent
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end

end
