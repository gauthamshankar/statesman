require "spec_helper"
require "statesman/adapters/shared_examples"
require "statesman/adapters/active_record_enum_transition"
require "statesman/exceptions"

describe Statesman::Adapters::ActiveRecordEnum do
  let(:states_as_enum) { { :x => 1, :y => 2, :z => 3 } }

  before do
    prepare_enum_model_table
    allow(EnumActiveRecordTransition).to receive(:enum_for_state) do |arg|
      states_as_enum[arg]
    end
  end

  let(:observer) do
    result = double(Statesman::Machine)
    allow(result).to receive(:execute)
    result
  end


  let(:model) { EnumActiveRecordModel.create }
  it_behaves_like "an adapter", described_class,
    EnumActiveRecordTransition
end
