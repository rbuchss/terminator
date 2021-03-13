# frozen_string_literal: true
require 'forwardable'

module Terminator
  class PryConfig
    extend Forwardable

    def_delegators(
      :@pry,
      :editor, :editor=,
      :hooks,
      :prompt, :prompt=
    )

    PLUGINS = [
      'pry-doc',
      'awesome_print',
      'readline',
      # 'pry-byebug',
      # 'pry-stack_explorer',
      # 'pry-git',
      # 'pry-remote',
    ].freeze

    PROMPT_PREFIX = "#{RUBY_ENGINE}-#{RUBY_VERSION}".freeze

    def initialize
      @pry = Pry

      load_plugins

      self.editor = 'vim'
      self.prompt = Pry::Prompt.new(
        'custom',
        'custom-prompt',
        [ prompt_proc('>'), prompt_proc('*') ]
      )

      hooks.add_hook(:when_started, :list_gemsets) do
        if defined?(Bundler)
          puts '--- gemsets ---'
          Gem.path.each do |gemset|
            puts gemset
          end
        end
      end

      hooks.add_hook(:after_session, :say_bye) do
        puts 'tchau'
      end

      setup_custom_commands
    end

    private

    def load_plugins
      @load_error = false

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
    end

    def prompt_prefix(obj, nest_level, pry)
      "[#{pry.input_ring.size}] #{PROMPT_PREFIX} (#{obj})#{":#{nest_level}" if nest_level > 0}"
    end

    def prompt_proc(suffix)
      proc do |obj, nest_level, pry|
        "#{prompt_prefix(obj, nest_level, pry)}#{suffix} "
      end
    end

    def setup_custom_commands
      if defined?(::ActiveRecord)
        Pry::Commands.block_command(:show_tables,
                                    'Shows tables in the database',
                                    keep_retval: true) do
          ::ActiveRecord::Base.connection.tables
        end
      end
    end
  end
end

Terminator::PryConfig.new
