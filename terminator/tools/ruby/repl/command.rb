# frozen_string_literal: true
require 'forwardable'

module Terminator
  module REPL
    Command = Struct.new(:name, :desc, :aliases, :command, :options) do
      extend Enumerable
      @_all = {}
      @_aliases = {}

      class << self
        extend Forwardable
        def_delegator :@_all, :values, :all
        def_delegator :@_all, :[]

        def each(&block)
          return all.to_enum unless block_given?
          all.each { |member| block.call(member) }
        end

        def add(member)
          @_all[member.name] = member
          member.aliases.each { |alias_name| @_aliases[alias_name] = member }
        end

        def help(name = nil)
          unless name
            puts "#{self}: available commands:"
            longest_name = @_all.keys.max_by(&:length)
            all.each { |member| member.short_help(longest_name.length) }
            return
          end

          unless command = @_all[name] || @_aliases[name]
            return warn "#{self}: '#{name}' not found!"
          end

          command.help
        end
      end

      def initialize(name:, desc: '', aliases: [], command: proc {}, options: {}, &block)
        super(name, desc, aliases, command, { context: :command }.merge(options))
        self.class.add(self)
        define_singleton_method(:run, &command)
        instance_eval(&block) if block_given?
      end

      def bind(base)
        case options[:context]
        when :command
          this = self

          # NOTE: keyword arguments are handled differently over ruby 2.6, 2.7, and 3.0
          # see:
          #   https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/
          #
          ruby_version = Gem::Version.new(RUBY_VERSION)

          if ruby_version >= Gem::Version.new('3.0')
            base.send(:define_method, name) { |*args, **kwargs, &block| this.run(*args, **kwargs, &block) }
          else
            base.send(:define_method, name) { |*args, &block| this.run(*args, &block) }
            base.send(:ruby2_keywords, name) if ruby_version >= Gem::Version.new('2.7')
          end
        else
          base.send(:define_method, name, &command)
        end

        aliases.each { |alias_name| base.send(:alias_method, alias_name, name) }
      end

      def help
        printf("%s[:%s]: %s\nparameters:\t%s\naliases:\t%s\nlocation:\t%s:%s\n",
               self.class, name, desc, command.parameters, aliases, *command.source_location)
        printf("source:\n%s", command.respond_to?(:source) ?
               command.source : "\t\tNot available [method_source gem missing!]\n")
      end

      def short_help(padding = 0)
        printf("\t%1$*2$s: %3$s\n", name, padding, desc)
      end
    end
  end
end

Dir[File.join(__dir__, 'commands', '*.rb')].each { |file| require file }
