require "spec_helper"
require "statesman/adapters/shared_examples"
require "statesman/adapters/active_record_enum_transition"
require "statesman/adapters/active_record_enum_exceptions"

describe Statesman::Adapters::ActiveRecordEnum do
  let(:states_as_enum) { { x: 1, y: 2, z: 3 } }
  let(:enums_as_state) { states_as_enum.invert }

  before do
    prepare_enum_model_table
    allow(EnumActiveRecordTransition).to receive(:enum_for_state) do |arg|
      states_as_enum[arg]
    end

    allow(EnumActiveRecordTransition).to receive(:state_for_enum) do |arg|
      enums_as_state[arg]
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

  describe "#initialize" do
    context "specified enum column is not present in model" do
      before do
        # throws up an error during model instance creation
        model
        allow(EnumActiveRecordModel).to receive_messages(columns_hash: {})
      end

      it "raises an EnumColumnNotFoundError" do
        expect do
          described_class.new(EnumActiveRecordTransition,
                              model, observer)
        end.to raise_exception(Statesman::Adapters::EnumColumnNotFoundError)
      end
    end

    context "column is not of type integer" do
      before do
        model
        enum_column = double
        allow(enum_column).to receive_messages(type: :string)
        allow(EnumActiveRecordModel).to receive_messages(columns_hash:
                                        { 'enum_state' => enum_column })
      end

      it "raises an IncompatibleEnumColumnTypeError" do
        expect do
          described_class.new(EnumActiveRecordTransition,
                              model, observer)
        end.to raise_exception(
          Statesman::Adapters::IncompatibleEnumColumnTypeError)
      end
    end

    describe "#create" do
      let!(:adapter) do
        described_class.new(EnumActiveRecordTransition, model, observer)
      end
      let(:from) { :x }
      let(:to) { :y }
      let(:there) { :z }
      let(:create) { adapter.create(from, to) }
      subject { -> { create } }

      context "when state does not have an associated enum" do
        let(:states_as_enum) { {} }
        it do
          is_expected.to raise_exception(
            Statesman::Adapters::MissingEnumForStateError)
        end
      end

      context "with no previous transition, i.e enum_state is nil" do
        subject { model }
        its(:enum_state) { is_expected.to be(nil) }

        context "the enum_state should be updated to new state value" do
          before { adapter.create(from, to) }
          its(:enum_state) { is_expected.to be(2) }
        end
      end

      context "parent model with a previous transition," \
        "i.e enum_state has value" do
        subject { model }
        before do
          adapter.create(from, to)
        end
        its(:enum_state) { is_expected.to be(2) }

        context "the enum_state should be updated to new state value" do
          before { adapter.create(to, there) }
          its(:enum_state) { is_expected.to be(3) }
        end
      end

      context "rollback enum_state if AR transaction fails" do
        before do
          model.enum_state = 1
          model.save!
        end

        context "model save raises an exception" do
          before do
            allow_any_instance_of(EnumActiveRecordModel)
              .to receive(:save!).and_raise(StandardError)
          end

          it "rollback's the model data" do
            expect { adapter.create(from, to) }
              .to raise_exception(StandardError)
            model.reload
            expect(model.enum_state).to eq(1)
          end
        end

        context "observer execute raises an exception" do
          let(:observer) do
            result = double(Statesman::Machine)
            # specifically after because the save gets over and make sure that
            # the rollback happens
            allow(result).to receive(:execute) do |arg|
              raise StandardError if arg.eql?(:after)
            end
            result
          end

          it "rollback's the model data" do
            expect { adapter.create(from, to) }
              .to raise_exception(StandardError)
            model.reload
            expect(model.enum_state).to eql(1)
          end
        end
      end
    end

    describe "#last" do
      let(:adapter) do
        described_class.new(EnumActiveRecordTransition, model, observer)
      end

      before do
        temp_adapter = described_class.new(EnumActiveRecordTransition, model,
                                           observer)
        temp_adapter.create(:x, :y)
      end

      context "with persisted data but no history in memory" do
        it "retrieves the new transition from the model" do
          expect(adapter).to receive(:load_history)
          adapter.last
        end

        it "returns persisted transition" do
          expect(adapter.last.to_state).to eql("y")
        end
      end

      context "model has no state data (initial state)" do
        it "returns nil for last transition" do
          new_model = EnumActiveRecordModel.create
          new_adapter = described_class.new(EnumActiveRecordTransition,
                                            new_model, observer)
          expect(new_adapter.last).to be_nil
        end
      end

      context "with a pre-fetched transition history" do
        before do
          adapter.last
        end

        it "does not load again if data is pre-fetched" do
          expect(adapter).not_to receive(:load_history)
          adapter.last
        end

        it "returns last transition from history" do
          adapter.create(:y, :x)
          expect(adapter).not_to receive(:load_history)
          expect(adapter.last.to_state).to eql("x")
        end
      end
    end

  end
end
