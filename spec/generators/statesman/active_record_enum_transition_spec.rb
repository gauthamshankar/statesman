require "spec_helper"
require "support/generators_shared_examples"
require "generators/statesman/active_record_enum_generator"

describe Statesman::ActiveRecordEnumGenerator, type: :generator do

  it_behaves_like "a generator" do
    let(:migration_name) { 'db/migrate/add_statesman_to_bacons.rb' }
  end

  describe 'the migration contains the correct words' do
    let(:migration_number) { '5678309' }

    let(:mock_time) do
      double('Time', utc: double('UTCTime', strftime: migration_number))
    end

    subject do
      file(
        "db/migrate/#{migration_number}_add_statesman_to_bacons.rb"
      )
    end

    context "default column name" do
      before do
        allow(Time).to receive(:now).and_return(mock_time)
        run_generator %w(Yummy::Bacon Yummy::BaconTransition)
      end

      it { is_expected.to contain(/:bacon/) }
      it { is_expected.to contain(/:enum_state/) }
    end

    context "passed column name value" do
      before do
        allow(Time).to receive(:now).and_return(mock_time)
        run_generator %w(Yummy::Bacon Yummy::BaconTransition bacon_state)
      end

      it { is_expected.to contain(/:bacon/) }
      it { is_expected.to contain(/:bacon_state/) }
    end
  end

  describe 'properly adds class names' do
    before { run_generator %w(Yummy::Bacon Yummy::BaconTransition) }
    subject { file('lib/statesman/yummy/bacon_transition.rb') }

    it { is_expected.to contain(/class Yummy::BaconTransition/) }
    it { is_expected.to contain(/state_column :enum_state/) }
  end

  describe 'properly formats without class names' do
    before { run_generator %w(Bacon BaconTransition) }
    subject { file('lib/statesman/bacon_transition.rb') }

    it { is_expected.to contain(/class BaconTransition/) }
    it { is_expected.to contain(/state_column :enum_state/) }
  end

  describe 'properly adds column name' do
    before { run_generator %w(Bacon BaconTransition bacon_state) }
    subject { file('lib/statesman/bacon_transition.rb') }

    it { is_expected.to contain(/state_column :bacon_state/) }
  end
end
