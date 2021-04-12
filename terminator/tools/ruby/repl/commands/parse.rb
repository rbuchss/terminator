# frozen_string_literal: true
require 'ripper'

Terminator::REPL::Command.new(
  name: :parse,
  desc: 'Generate symbolic expression of ruby code',
  command:
    -> (thing, file: false) do
      code = case thing
             when Proc, Method
               unless thing.respond_to?(:source)
                raise ArgumentError, 'source not available [method_source gem missing!]'
               end

               thing.source
             when String
               file ?
                 File.read(File.expand_path(thing)) :
                 thing
             else
               raise ArgumentError, "type: '#{thing.class}' not supported (must be Proc, Method, or String)"
             end

      Ripper.sexp(code)
    end
)
