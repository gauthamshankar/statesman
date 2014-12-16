require "spec_helper"
require "statesman/adapters/active_record_enum_exceptions"

describe Statesman::Adapters::ActiveRecordEnumTransition do
  let(:transition_class) { Class.new }

  before do
    transition_class.send(:include, described_class)
  end

  subject { transition_class }

  describe "#initialize" do
    let(:transition_object) do
      transition_class.new("x", 100, key: "value")
    end

    subject { transition_object }
    its(:created_at) { is_expected.to be_kind_of(Time) }
    its(:updated_at) { is_expected.to be_kind_of(Time) }
    its(:to_state) { is_expected.to eql("x") }
    its(:sort_key) { is_expected.to eql(100) }
    its(:metadata) { is_expected.to eql(key: "value") }
  end

  describe "#state_column" do
    before { transition_class.state_column(:e_column) }
    its(:enum_column) { is_expected.to eql(:e_column) }
  end

  describe "#states_as_enum" do
    before do
      transition_class.states_as_enum(
       initial:   1,
       succeeded: 2,
       failed:    3
      )
    end

    it "sets the state_enum instance variable with hash" do
      expect(subject.instance_variable_get(:@state_enum)).to eql(
        initial:   1,
        succeeded: 2,
        failed:    3
      )
    end

    it "sets the enum_state with a reverse map of the hash passed" do
      expect(subject.instance_variable_get(:@enum_state)).to eql(
        1 => :initial,
        2 => :succeeded,
        3 => :failed
      )
    end
  end

  describe "#enum_column" do
    it "returns the enum column name" do
      transition_class.state_column(:e_column)
      expect(transition_class.enum_column).to eql(:e_column)
    end

    it "returns default value when column name not given" do
      expect(transition_class.enum_column).to eql(:enum_state)
    end
  end

  describe "#enum_for_state" do
    before do
      transition_class.states_as_enum(initial:   1,
                                      succeeded: 2,
                                      failed:    3)
    end

    it "returns enum for given state" do
      expect(transition_class.enum_for_state(:failed)).to eql(3)
    end

    it "returns nil when state not found" do
      expect(transition_class.enum_for_state(:unkown)).to be_nil
    end

  end

  describe "#state_for_enum" do
    before do
      transition_class.states_as_enum(initial:   1,
                                      succeeded: 2,
                                      failed:    3)
    end

    it "returns state name for given enum" do
      expect(transition_class.state_for_enum(2)).to eql(:succeeded)
    end

    it "returns nil when enum not found" do
      expect(transition_class.state_for_enum(5)).to be_nil
    end
  end

  describe "#validate_enum_map" do
    # change the it description
    it "raises an error if enum value is only integer" do
      transition_class.states_as_enum(initial:   1,
                                      succeeded: "2",
                                      failed:    "3")
      expect { transition_class.validate_enum_map }
        .to raise_exception(Statesman::Adapters::InvalidEnumError)
    end

    it "raises an error if enum values are not uniqe" do
      transition_class.states_as_enum(initial:   1,
                                      succeeded: 1,
                                      failed:    3)
      expect { transition_class.validate_enum_map }
        .to raise_exception(Statesman::Adapters::EnumConflictError)
    end
  end
end
