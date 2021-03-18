# frozen_string_literal: true

# begin
#   require 'pry'
#   Pry.start
#   exit
# rescue LoadError => e
#   warn "=> Unable to load pry #{e}"
# end

begin
  require '~/.ruby_friends/repl/support.rb'
  module IRB::ExtendCommandBundle
    include ::Terminator::REPL::Support
  end
rescue LoadError => e
  warn "=> #{e}"
end
