require 'autogrid/column'
require 'autogrid/util'
module Autogrid
  class Table
    attr_accessor :cookies, :session, :view, :params
    
    attr_reader :record, :klass, :columns
    
    def default_options
      { :id           => lambda{ "autogrid_#{params[:controller]}_#{params[:action]}" },
        :paginate     => false,
        :sortable     => false,
        :filterable   => false,
        :html_options => {
          :class => 'autogrid',
          :id    => nil
        },
        :ajax => false
      }
    end
    
    # Define formatters
    def formatters
      {
        :plain => lambda{|col,opts| col.value },
        :link  => lambda{|col,opts| opts.blank? ? view.link_to(col.plain, col.model) : view.link_to(col.plain, opts) },
        :proc  => lambda{|col,opts| opts.call(col) }
      }
    end
    
    @@options_proc ={
      :paginate => lambda{|v,opts| raise ArgumentError, "The 'kaminari' gem must be enabled for pagination" if(v && !defined?(Kaminari::VERSION))  }
    }
    
    def options
      @options.blank? ? default_options : @options
    end
    
    def initialize(record, params)
      if !record.is_a?(ActiveRecord::Base) and !record.is_a?(ActiveRecord::Relation)
        raise ArgumentError, "Passed record is not an ActiveRecord::Base or ActiveRecord::Relation Object!"
      end
      @params = params
      @record  = record
      @klass   = record.is_a?(ActiveRecord::Relation) ? record.klass : record.class
      @columns = ActiveSupport::OrderedHash.new
      update_options(*options)
    end
    
    def update_options(*the_options)
      @options = Util.optionize(options, @@options_proc, *the_options)
    end
    
    def to_html
      raise ArgumentError, "Cannot call `to_html` when not in view context!" if view.blank?
      view.render :partial => 'autogrid/table', :object => self
    end
    
    def col(*args, &block)
      options = args.extract_options!
      args.each do |c|
        kol = c.to_s
        if columns.key?(kol)
          columns[kol].update_options(options)
          columns[kol].block = block if block_given?
        else
          columns[kol] = Column.new(self, kol, options, &block)
        end
      end
    end
    
    # Loops through each grid
    def each(&block)
      record.each do |record|
        block.call(record)
      end
    end
    
    
  end
end
