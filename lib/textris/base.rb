module Textris
  class Base
    extend Textris::Delay::Sidekiq

    class << self
      def deliveries
        ::Textris::Delivery::Test.deliveries
      end

      def with_defaults(options)
        defaults.merge(options)
      end

      def defaults
        @defaults ||= superclass.respond_to?(:defaults) ? superclass.defaults.dup : {}
      end

      protected

      def default(options)
        defaults.merge!(options)
      end

      private

      def method_missing(method_name, *args, **kwargs)
        new(method_name, *args, **kwargs).call_action
      end

      def respond_to_missing?(method, *)
        public_instance_methods(true).include?(method) || super
      end
    end

    def initialize(action, *args, **kwargs)
      @action = action
      @args   = args
      @kwargs = kwargs
    end

    def call_action
      send(@action, *@args, **@kwargs)
    end

    def render_content
      renderer = ::ActionController::Base.renderer.new

      renderer.render(
        template: template_name,
        layout: false,
        formats: [:text],
        locale: @locale,
        assigns: set_instance_variables_for_rendering
      )
    end

    protected

    def text(options = {})
      @locale = options[:locale] || I18n.locale

      options = self.class.with_defaults(options)
      options.merge!(
        :texter     => self.class,
        :action     => @action,
        :args       => @args,
        :kwargs     => @kwargs,
        :content    => options[:body].is_a?(String) ? options[:body] : nil,
        :renderer   => self)

      ::Textris::Message.new(options)
    end

    private

    def template_name
      class_name  = self.class.to_s.underscore.sub('texter/', '')
      action_name = @action

      "texters/#{class_name}/#{action_name}"
    end

    def set_instance_variables_for_rendering
      instance_variables.map do |var|
        [var.to_s.sub('@', ''), instance_variable_get(var)]
      end.to_h
    end
  end
end
