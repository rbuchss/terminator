# frozen_string_literal: true

Terminator::REPL::Command.new(
  name: :disassemble,
  desc: 'Disassemble ruby code',
  aliases: %i(disasm),
  command:
    -> (thing, file: false, of: false) do
      iseq = case thing
             when Proc, Method
               RubyVM::InstructionSequence.of(thing)
             when String
               file ?
                 RubyVM::InstructionSequence.compile_file(thing) :
                 RubyVM::InstructionSequence.compile(thing)
             else
               raise ArgumentError, "type: '#{thing.class}' not supported (must be Proc, Method, or String)"
             end

      of ? iseq : puts(iseq.disasm)
    end
)
