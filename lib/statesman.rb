module Statesman
  autoload :Config,     'statesman/config'
  autoload :Machine,    'statesman/machine'
  autoload :Callback,   'statesman/callback'
  autoload :Guard,      'statesman/guard'
  autoload :Version,    'statesman/version'
  module Adapters
    autoload :Memory,       "statesman/adapters/memory"
    autoload :ActiveRecord, "statesman/adapters/active_record"
    autoload :ActiveRecordTransition,
             "statesman/adapters/active_record_transition"
    autoload :ActiveRecordQueries,
             "statesman/adapters/active_record_queries"
    autoload :ActiveRecordEnum,   "statesman/adapters/active_record_enum"
    autoload :ActiveRecordEnumTransition,
             "statesman/adapters/active_record_enum_transition"
    autoload :ActiveRecordEnumQueries,
             "statesman/adapters/active_record_enum_queries"
    autoload :Mongoid,      "statesman/adapters/mongoid"
    autoload :MongoidTransition,
             "statesman/adapters/mongoid_transition"
  end

  # Example:
  #   Statesman.configure do
  #     storage_adapter Statesman::ActiveRecordAdapter
  #   end
  #
  def self.configure(&block)
    config = Config.new(block)
    @storage_adapter = config.adapter_class
  end

  def self.storage_adapter
    @storage_adapter || Adapters::Memory
  end
end
