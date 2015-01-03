require_relative "active_record_enum_exceptions"

module Statesman
  module Adapters
    module ActiveRecordEnumTransition
      def self.included(base)
        base.class_exec do
          def initialize(to, sort_key, metadata = nil)
            @created_at = Time.now
            @updated_at = Time.now
            @to_state = to
            @sort_key = sort_key
            @metadata = metadata
          end
        end

        base.extend(ClassMethods)
        base.send(:attr_accessor,
                  :created_at, :updated_at, :to_state,
                  :sort_key, :metadata)
      end

      module ClassMethods
        # rubocop:disable TrivialAccessors
        def state_column(column)
          @enum_column = column
        end

        def states_as_enum(state_enum_hash)
          @state_enum = state_enum_hash
          @enum_state = @state_enum.invert
        end
        # rubocop:enable TrivialAccessors

        def enum_column
          @enum_column ||= :enum_state
        end

        def enum_for_state(state)
          @state_enum[state]
        end

        def state_for_enum(enum)
          @enum_state[enum]
        end

        # why only these two errors are being raised from here
        # why not when the state is not found when asking for
        # enum_for_state or state_for_enum
        def validate_enum_map
          # Enum itself is a datatype, please change the message
          raise InvalidEnumError, "Enum can only be of type integer" unless
            @state_enum.values.all? { |e| e.is_a? Fixnum }
          raise EnumConflictError, "States need to have unique enum value" if
            @state_enum.values.uniq!
        end
      end
    end
  end
end
