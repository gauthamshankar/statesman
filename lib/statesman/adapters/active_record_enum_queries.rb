module Statesman
  module Adapters
    module ActiveRecordEnumQueries
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def in_state(*states)
          where(state_inclusion_where(states),
                states.map { |state| transition_class.enum_for_state(state) })
          # raise error ?
        end

        def not_in_state(*states)
          where("NOT (#{state_inclusion_where(states)})",
                states.map { |state| transition_class.enum_for_state(state) })
          # raise error ?
        end

        private

        def transition_class
          raise NotImplementedError, "A transition_class method should be " \
                                     "defined on the model"
        end

        def column_name
          transition_class.enum_column
        end

        def initial_state
          raise NotImplementedError, "An initial_state method should be " \
                                     "defined on the model"
        end

        def state_inclusion_where(states)
          if initial_state.to_s.in?(states.map(&:to_s))
            "#{column_name} IN (?) OR " \
            "#{column_name} IS NULL"
          else
            "#{column_name} IN (?) AND " \
            "#{column_name} IS NOT NULL"
          end
        end
      end
    end
  end
end
