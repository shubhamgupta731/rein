require 'rein/util'

module Rein
  module Constraint
    # This module contains methods for defining presence constraints.
    module Presence
      include ActiveRecord::ConnectionAdapters::Quoting

      def add_presence_constraint(*args)
        reversible do |dir|
          dir.up do _add_presence_constraint(*args) end
          dir.down { _remove_presence_constraint(*args) }
        end
      end

      def remove_presence_constraint(*args)
        reversible do |dir|
          dir.up do _remove_presence_constraint(*args) end
          dir.down { _add_presence_constraint(*args) }
        end
      end

      private

      def _add_presence_constraint(table, attribute, options = {})
        name = Util.constraint_name(table, attribute, 'presence', options)
        table = Util.wrap_identifier(table)
        attribute = Util.wrap_identifier(attribute)
        check_conditions = ["(#{attribute} IS NOT NULL)"]

        # Handle presence for range datatypes
        check_conditions << case options[:column_type].to_s
        when /^.*range$/
          range_presence_constraint(attribute)
        else
          generic_presence_constraint(attribute)
        end
        conditions = Util.conditions_with_if(
          check_conditions.join(' AND '),
          options
        )
        execute("ALTER TABLE #{table} ADD CONSTRAINT #{name} CHECK (#{conditions})")
      end

      def _remove_presence_constraint(table, attribute, options = {})
        name = Util.constraint_name(table, attribute, 'presence', options)
        table = Util.wrap_identifier(table)
        execute("ALTER TABLE #{table} DROP CONSTRAINT #{name}")
      end

      def generic_presence_constraint(attribute)
        "(#{attribute} !~ '^\\s*$')"
      end

      def range_presence_constraint(attribute)
        "(#{attribute} != 'empty')"
      end
    end
  end
end
