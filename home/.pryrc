# We do this here as well in case pry was not started through IRB,
# but for example from rails console with pry being in the Gemfile
$LOAD_PATH.push(*Dir["#{ENV['HOME']}/.prygems/gems/*/lib"]).uniq!

PLUGINS = %w(
  pry-doc
  awesome_print
  readline
)
#
# pry-byebug
# pry-stack_explorer
# pry-git
# pry-remote
#

PLUGINS.each do |name|
  begin
    require name
  rescue LoadError
    puts "\e[31mFailed\e[0m loading '#{name}'"
    @load_error = true
  end
end

if @load_error
  puts "\e[2mInstall them with `gem` or add them in `bundler` (if needed)\e[0m"
end

Pry.config.editor = 'vim'
Pry.editor = 'vim'

Pry.config.hooks.add_hook(:after_session, :say_bye) do
  puts "tchau"
end

# Prompt with ruby version
PROMPT_PREFIX = "#{RUBY_ENGINE}-#{RUBY_VERSION}"

def prompt_prefix(obj, nest_level, pry)
  "[#{pry.input_ring.size}] #{PROMPT_PREFIX} (#{obj})#{":#{nest_level}" if nest_level > 0}"
end

Pry.config.prompt = Pry::Prompt.new(
  'custom',
  'custom-prompt',
  [
    proc { |obj, nest_level, pry| "#{prompt_prefix(obj, nest_level, pry)}> " },
    proc { |obj, nest_level, pry| "#{prompt_prefix(obj, nest_level, pry)}* " }
  ]
)

Gem.path.each do |gemset|
  puts gemset
  #$:.concat(Dir.glob("#{gemset}/gems/pry-*/lib"))
end if defined?(Bundler)
##$:.uniq!

#Pry.load_plugins if Pry.config.should_load_plugins

module Kernel
  def show_tables
    ActiveRecord::Base.connection.tables
  end
end
