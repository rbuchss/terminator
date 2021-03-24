# frozen_string_literal: true

module Terminator
  module REPL
    Command = Struct.new(:name, :desc, :command, :options) do
      extend Enumerable
      @_all = {}

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
        end

        def help(name)
          unless command = @_all[name]
            return warn "#{self}: '#{name}' not found!"
          end
          command.help
        end
      end

      def initialize(name:, desc: '', command: proc {}, options: {}, &block)
        super(name, desc, command, { context: :command }.merge(options))
        self.class.add(self)
        define_singleton_method(:run, &command)
        instance_eval(&block) if block_given?
      end

      def bind(base)
        case options[:context]
        when :command
          this = self
          base.send(:define_method, name) do |*args, &block|
            this.run(*args, &block)
          end
        else
          base.send(:define_method, name, &command)
        end
      end

      def help
        printf("%s[:%s]: %s\nparameters:\t%s\nlocation:\t%s:%s\n",
               self.class, name, desc, command.parameters, *command.source_location)
        printf("source:\n%s", command.respond_to?(:source) ?
               command.source : "\t\tNot available [method_source gem missing!]\n")
      end
    end
  end
end

Dir[File.join(__dir__, 'commands', '*.rb')].each { |file| require file }
