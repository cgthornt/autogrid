module Autogrid
  class Column
    attr_reader :table, :id, :attribute, :klass, :model, :value, :options, :format, :format_options
    
    attr_accessor :block
    
    def default_options
      {
      :format => :plain,
      :name   => lambda{ klass.human_attribute_name(attribute) },
      :html_options => {},
      :cell_html => {},
      }
    end
    
    @@options_proc = {
    }
    
    def initialize(table, name, the_options = {}, &the_block)
      @table = table
      @id  = name.to_s
      sp = name.to_s.split('.')
      @attribute = sp.pop
      begin
        @klass = sp.blank? ? table.record : sp.last.singularize.camelize.constantize
      rescue
        @klass = table.record
      end
      block = the_block
      
      update_options(the_options)
    end
    
    def update_model(model)
      @value = Util.nested_send(model, id)
      @model = model
    end
    
    def update_options(the_options = {})
      @options = Util.optionize((@options ||= default_options), @@options_proc, the_options)
      
      unless block.is_a?(Proc)
        @format = options[:format]
        @format_options = {}
        if @format.is_a?(Hash)
          @format,@format_options = @format.first
        end
        raise ArgumentError, "Format '#{@format}' is not supported!" unless table.formatters.key?(@format)
      end
    end
    
    def plain
      value
    end
    
    def formatted
      return block.is_a?(Proc) ? block.call(self,plain) : table.formatters[@format].call(self, @format_options)
    end
    
  end
end
