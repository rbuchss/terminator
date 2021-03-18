# frozen_string_literal: true
require 'benchmark'

Terminator::REPL::Command.new(
  name: :time,
  desc: 'Report time consumed by statement\'s execution',
  command:
    -> &block do
      raise ArgumentError, 'no block given' unless block
      result = nil
      bm = ::Benchmark.measure { result = block.call }
      printf('%s%s', ::Benchmark::CAPTION, bm)
      result
    end
)
