require "json"

class EnumStateMachine
  include Statesman::Machine

  state :initial, initial: true
  state :succeeded
  state :failed

  transition from: :initial, to: [:succeeded, :failed]
  transition from: :failed,  to: :initial
end

class EnumActiveRecordModel < ActiveRecord::Base
  def state_machine
    @state_machine ||= EnumStateMachine.new(
      self, transition_class: EnumActiveRecordTransition)
  end
end

class EnumActiveRecordTransition
  include Statesman::Adapters::ActiveRecordEnumTransition

  states_as_enum initial:   1,
                 succeeded: 2,
                 failed:    3
end

class CreateEnumActiveRecordMigration < ActiveRecord::Migration
  def change
    create_table :enum_active_record_models do |t|
      t.integer :enum_state
      t.timestamps
    end
  end
end
