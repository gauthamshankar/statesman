require "rails/generators"
require "generators/statesman/generator_helpers"

module Statesman
  class ActiveRecordEnumGenerator < Rails::Generators::Base
    include Statesman::GeneratorHelpers

    desc "Add a enum attribute to the parent model and"\
         "create transition class with required attributes"

    argument :parent,       type: :string, desc: "Your parent model name"
    argument :klass,        type: :string, desc: "Your transition model name"
    argument :column_name,  type: :string, desc: "Enum column name for parent",
                            default: "enum_state"

    source_root File.expand_path('../templates', __FILE__)

    def create_model_file
      template("update_enum_migration.rb.erb", migration_file_name)
      template("active_record_enum_transition_class.rb.erb", enum_lib_file_name)
    end

    private

    def migration_file_name
      # remove generic table name from generator helpers
      "db/migrate/#{next_migration_number}_add_statesman_to_" \
      "#{parent_name.pluralize}.rb"
    end
  end
end
