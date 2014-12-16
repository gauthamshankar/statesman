require "spec_helper"

describe Statesman::Adapters::ActiveRecordEnumQueries do
  before do
    prepare_enum_model_table
  end

  before do
    EnumActiveRecordModel.send(:include,
                               Statesman::Adapters::ActiveRecordEnumQueries)
    EnumActiveRecordModel.class_eval do
      def self.transition_class
        EnumActiveRecordTransition
      end

      def self.initial_state
        :initial
      end
    end
  end

  let!(:model) do
    model = EnumActiveRecordModel.new
    model.enum_state = 2
    model.save!
    model
  end

  let!(:other_model) do
    model = EnumActiveRecordModel.new
    model.enum_state = 3
    model.save!
    model
  end

  let!(:initial_state_model) { EnumActiveRecordModel.create }

  let!(:returned_to_initial_model) do
    model = EnumActiveRecordModel.new
    model.enum_state = 3
    model.save!
    model.enum_state = 1
    model.save!
    model
  end

  describe ".in_state" do
    context "given a single state" do
      subject { EnumActiveRecordModel.in_state(:succeeded) }

      it { is_expected.to include model }
    end

    context "given multiple states" do
      subject { EnumActiveRecordModel.in_state(:succeeded, :failed) }

      it { is_expected.to include model }
      it { is_expected.to include other_model }
    end

    context "given the initial state" do
      subject { EnumActiveRecordModel.in_state(:initial) }

      it { is_expected.to include initial_state_model }
      it { is_expected.to include returned_to_initial_model }
    end
  end

  describe ".not_in_state" do
    context "given a single state" do
      subject { EnumActiveRecordModel.not_in_state(:failed) }
      it { is_expected.to include model }
      it { is_expected.not_to include other_model }
    end

    context "given multiple states" do
      subject { EnumActiveRecordModel.not_in_state(:succeeded, :failed) }
      it do
        is_expected.to match_array([initial_state_model,
                                    returned_to_initial_model])
      end
    end
  end
end
