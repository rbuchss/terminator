# frozen_string_literal: true
require 'set'

Terminator::REPL::Command.new(
  name: :subclasses_of,
  desc: 'Get all subclasses of a superclass',
  command:
    -> (superclass, singleton_classes: false) do
      subclasses = Set.new
      ObjectSpace.each_object(Class) do |k|
        next if !k.ancestors.include?(superclass) ||
          superclass == k ||
          !singleton_classes && k.singleton_class?
        subclasses << k
      end
      subclasses
    end
)
