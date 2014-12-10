module Statesman
  module Adapters
    class InvalidEnumError < StandardError; end
    class EnumConflictError < StandardError; end
    class MissingEnumForStateError < StandardError; end
    class EnumColumnNotFoundError < StandardError; end
    class IncompatibleEnumColumnTypeError < StandardError; end
  end
end
