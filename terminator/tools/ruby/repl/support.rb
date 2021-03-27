# frozen_string_literal: true
require_relative './command.rb'

module Terminator
  module REPL
    module Support
      def self.included(base)
        mod = Module.new do
          Command.each { |command| command.bind(self) }

          def custom_help(name = nil)
            Command.help(name)
          end

          alias :chelp :custom_help
        end

        if defined?(::Pry)
          TOPLEVEL_BINDING.receiver.extend(mod)
        else
          include mod
        end
      end
    end
  end
end
