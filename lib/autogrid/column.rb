# Represents a grid column!
module Autogrid
  class Column
    
    # An unique String ID of this column
    attr_accessor :id
    
    # The name of this column, which should be human readable
    attr_accessor :name
    
    # todo: comment these
    attr_accessor :html, :header_html, :visible, :hidden, :filter, :use_db,
      :sortable, :sort_order, :format, :format_options, :always_visible
    attr_reader :grid, :db_column, :db_table, :db_fullname
    
    # Makes a new column!
    # == Parameters
    # * +grid+ - a Flexigrid object'
    # * +id+ - The ID for this column
    # * +name+ - an optional human readable name for this column. If one is not
    #   given, then one will automatically be generated.
    def initialize(grid, id, name = nil)
      @grid = grid
      @id = id
      @sortable = true
      # Databaseize stuff
      id_s = id.split('.')
      @db_column = id_s.last
      @db_table = id_s.count == 1 ? @grid.model_class.table_name : id_s[id_s.count - 2].tableize
      @db_fullname = "`#{@db_table}`.`#{@db_column}`"
      if name.nil?
        if @grid.model.is_a? ActiveRecord::Relation
          @name = @grid.model.klass.human_attribute_name(@db_column)
        elsif @grid.model.is_a? ActiveRecord::Base
            @name = @grid.model.class.human_attribute_name(@db_column)
        else
          raise "Grid model must be an ActiveRecord type of object!"
        end
      else
        @name = name
      end
      # Defaults
      @hidden = @visible = false
    end
    
    def to_sort
      return 'asc' if @sort_order.blank? or @sort_order == 'DESC'
      return 'desc'
    end
    
    def update!
    end
    
    def sortable?
      @sortable
    end
    
    def sort_col?
      !@sort_order.blank?
    end
    
    def render(actionView, mdl)
      data = Misc::nested_send(mdl, @id)
      return actionView.capture(data,mdl,&filter) unless filter.blank?
      if !@format.nil? and Flexigrid::Formatter.respond_to? @format
        return Flexigrid::Formatter.send(@format, actionView, data, @format_options)
      end
      return data
    end
    
    
    # Whether this column is the one being used for sorting
    def sort?
      @grid.sort == self
    end
    
    # Whether this column is hidden by default
    def hidden?
      @hidden
    end
    
    # Whether this column should currently be displayed
    def visible?
      @visible
    end
    
    def always_visible?
      @always_visible
    end
    
  end
end
