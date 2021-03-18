# frozen_string_literal: true

if defined?(::ActiveRecord)
  Terminator::REPL::Command.new(
    name: :show_tables,
    desc: 'Shows tables in the database',
    command:
      -> { ::ActiveRecord::Base.connection.tables }
  )
end
