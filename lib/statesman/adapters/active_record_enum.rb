require_relative "active_record_enum_exceptions"

module Statesman
  module Adapters
    class ActiveRecordEnum
      attr_reader :transition_class
      attr_reader :parent_model
      attr_reader :history

      def initialize(transition_class, parent_model, observer)
        column_name = transition_class.enum_column.to_s

        # forgot to run migration ? or maybe use the generator ?
        raise EnumColumnNotFoundError, 
              "Cannot find the enum column" if
              parent_model.class.columns_hash[column_name].blank?

        raise IncompatibleEnumColumnTypeError, 
              "Enum column should be of type int(11)" unless
              parent_model.class.columns_hash[column_name].sql_type.eql?("integer")

        @history = []
        @transition_class = transition_class
        @parent_model = parent_model
        @observer = observer
        @transition_class.validate_enum_map
      end

      def create(from, to, metadata = {})
        # do we need to convert to string? 
        from = from.to_s
        to = to.to_s
        create_transition(from, to, metadata)
      end

      def last
        # please use better conditionals ?
        if @history.blank? && 
          parent_model.send(transition_class.enum_column).present?
          load_history
        else
          # should we cache the result ? won't it be too much
          # complexitiy
          @history.sort_by(&:sort_key).last
        end
      end

      private

      def create_transition(from, to, metadata)
        transition = transition_class.new(to, next_sort_key, metadata)

        enum = transition_class.enum_for_state(to.to_sym)

        raise MissingEnumForStateError if enum.blank?

        parent_model.send(
          "#{transition_class.enum_column.to_s}=", enum
        )

        ::ActiveRecord::Base.transaction do
          @observer.execute(:before, from, to, transition)
          # if the parent_model is already in state, then it means
          # that someone already updated it or rather some process
          # should we throw an error for it ?
          parent_model.save!
          # not very happy about this. results in failing specs
          @history << transition
          @observer.execute(:after, from, to, transition)
        end
        @observer.execute(:after_commit, from, to, transition)

        transition
      end

      def next_sort_key
        (last && last.sort_key + 10) || 0
      end

      def load_history
        state_name = transition_class.state_for_enum(
          parent_model.send(transition_class.enum_column)
        ).to_s

        # should there be a state not found for enum error ?

        transition = transition_class.new(
          state_name,
          0,
          {}
        )
        @history << transition
        transition
      end
    end
  end
end
