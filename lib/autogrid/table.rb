# Represents a flexigrid that has many columns. A Flexigrid handles column
# sorting, ordering, pagination - the whole works. This is intended to be very
# flexible and the output of each column can easily be modified to fit any
# situation. Look at the flexigrid/column file for how to configure columns, and
# check out the flexigrid/formatter for a list of formatters.
#
# Flexigrid stores all of the column data in cookies. All of these columns are
# whitelisted, so that no SQL injections are possible.
# == How to Use
module Autogrid
  class Table
    
    # The title of the grid. If not set, displays the humanized class name of the
    # model passed to the flexigrid
    attr_accessor :title
    
    # HTML options to pass to the grid. Currently not implemented.
    attr_accessor :html
    
    # If true, then this deletes the cookie data and reloads column orders on
    # every request. Useful for development purposes. This *should* be set to
    # false when finished developing. Defaults to false.
    attr_accessor :reload
    
    # An unique ID for this flexigrid. This is used to uniquely store cookies.
    # Defaults to controller_view_modelname
    attr_accessor :id
    
    # A cookies object passed to the flexigrid. You should never have to manually
    # set this yourself, as it is handled through the application helper when
    # you call the "flexigrid" method. This is by default nil, but REQUIRED to be
    # set for the flexigrid to properly work.
    attr_accessor :cookies
    
    # Sets the column ID to sort by default. Defaults to "id"
    attr_accessor :default_sort
    
    # Allows each row to be clickable. By default, this automatically creates a
    # url by calling url_for on the current row model object. You may specify
    # a hash, which will call url_for on this hash, merged with the ID of the
    # current row. You may completely disable clicking functionality by setting
    # this to false.
    attr_accessor :url
    
    # NOTICE: This is currently broken and does not work!
    # If true, uses ajax for requests.
    attr_accessor :ajax
    
    # Sets whether to show the pagination bar. Defaults to true. If false, no
    # pagination bar is shown. It is up to the controller to set the model's
    # page() and per() methods.
    attr_accessor :paginate
    
    # Sets whether to "intelligently" select columns so that the query only fetches
    # the data needed (along with the ID of the current table). This is off by
    # default. This is currently experimental and not very intelligent.
    attr_accessor :auto_select
    
    # Whether columns should be editable or set to visible. Defaults to true
    attr_accessor :editable_columns
    
    # Force-add some additiona ORDER criteria after selected column sorting. Note
    # that this uses raw field names and is directly injected into a model's
    # order() method.
    attr_accessor :sort_after
    
    # Force-add some additonal ORDER criteria before selected column sorting Note
    # that this uses raw field names and is directly injected into a model's
    # order() method.
    attr_accessor :sort_before
    
    # Internal fields not changeable by the users.
    # * +columns+ - An array of column objects
    # * +model+ - The ActiveRecord object. Can either be an ActiveRecord::Base or
    #   ActiveRecord::Relation object
    # * +sort+ - Used to store an SQL sort query. Don't rely on this for anything, as I
    #   don't think it's very accurate
    # * +order+ - Not used, so I think. Keeping it here anyways
    # * +model_class+ - Stores the Class object for the model. Will always be a class
    #   of an ActiveRecord::Base object. Used to get the table name and also to get
    #   the default column names.
    # * +columns_hash+ - Internal hash used to link ID's and column objects
    # * +filter_block+ - Used by the filter method. If set, shows a filter container
    # * +hidden_columns_cache+ - Caches the hidden columns so that a new array of
    #   columns isn't rebuilt every time the method get_hidden_columns is called.
    # * +visible_columns_cache+ - Same as above, but with get_visible_columns
    # * +all_cols_cache+ - Same as above, but with all columns
    # * +original_model+ - Creates a copy of the original model before it's used. Useful for CSV export
    attr_reader :columns, :model, :sort, :order, :model_class, :columns_hash, :filter_block,
      :hidden_columns_cache, :visible_columns_cache, :all_cols_cache, :original_model, :filter_form
    
    # Creates a new Flexigrid object. Raises an exception if model is not either an
    # ActiveRecord::Base or ActiveRecord::Relation record
    # ==== Parameters
    # * +model+ - An ActiveRecord model. Please don't use the "order" method before
    #   passing it.
    # * +args+ - An array of symbol options to pass. If not a hash, then by default
    #   sets it to true. This internally sets any public variables (via attr_accessor)
    def initialize(model, *args)
      # Ensure they're passing the correct type
      if !model.is_a? ActiveRecord::Base and !model.is_a? ActiveRecord::Relation
        raise TypeError.new "Model passed to Flexigrid must be an ActiveRecord Base or Relation object"
      end
      
      # Some default options
      @editable_columns = true
      
      @model   = model
      @original_model = model
      @columns = Array.new
      @reload  = false
      @ajax    = false
      @paginate = true
      @columns_hash = Hash.new
  
      
      # Handle the two AR types that is accepted by Flexigrid
      @model_class = (model.is_a? ActiveRecord::Relation) ? model.klass : model.class
      
      # Is this actually unique? Grr rails...
      @unique_count = @unique_count ||= 0
      @unique_count += 1
      @id =  @model_class.name + "_#{@unique_count}"
      
      
      # Automatically handle options
      args.each do |arg|
        if arg.is_a? Symbol
          m = arg.to_s + '='
          self.send(m, true) if self.respond_to? m
        elsif arg.is_a? Hash
          arg.each do |k,v|
            m = k.to_s + '='
            self.send m, v if self.respond_to? m
          end
        end
      end
    end
    
    # Set a block to use to display a filter section on the grid (the blue area).
    # See the examples section on how to use
    def filter(filter_form_url = {}, filter_form_options = {:method => 'get'}, &block)
      raise 'You must pass a block to use for a filter' unless block_given?
      @filter_block = block
      @filter_form = {:url => filter_form_url, :options => filter_form_options}
    end
    
    # Instead of displaying data directly from the database, you can specify a block
    # to modify the output. You should usually call this in the view file. Will
    # raise an exception if +column+ is not found.
    # ==== Parameters
    # * +column+ - The ID of the column to modify
    # * +block+ - A block of data. Has two parameters, data and model. The data param
    # * is the direct value from the database, while the model param is the current
    # * row.
    # ==== Example Usage (in view file)
    # Simple data usage
    # # <% @grid.content_for :age do |data,mdl| %>
    # #   <%= data > 20 ? 'Old' : 'Young' %>
    # # <% end %>
    #
    # Using two parameters
    # # <% @grid.content_for :cardholder do |data,mdl| %>
    # #   <%= link_to data.name, {:id => mdl.id} %>
    # # <% end %>
    def content_for(column, &block)
      raise 'You must pass a block to use for field content' unless block_given?
      col_by_id(column, true).filter = block
    end
    
    
    # Renders some ajax. Not actually used for anything, so... don't call this :)
    def render_ajax
      {:partial => 'shared/flexigrid/ajax', :locals => {:grid => self}}
    end
    
    # Gets an array of columns
    def get_columns
      return @columns
    end
    
    # Internally called before rendering. At the moment, this simply orders the results
    def before_render
      select = get_select_query
      @model = @model.select(select) unless select.nil?
      @model = @model.order(@sort_before) unless @sort_before.blank?
      @model = @model.order(get_sort_query)
      @model = @model.order(@sort_after) unless @sort_after.blank?
    end
    
    # Internally called before exporting to CSV. This should be AS SIMILAR to the
    # before_render method above. However, this might exclude stuff dealing with
    # views, etc.
    def before_csv_render
      before_render
    end
    
    # Set a set of columns to use in the grid. Columns directly map to a model
    # field name (know to flexigrid as a column ID).
    # ==== Parameters
    # * +cols+ - a string of columns to use. They can be nested, for example, if
    #   using "joins" or "includes." You can add a colon at the end of an ID, followed
    #   by a title to change the title of the column
    # * +options+ - a hash of options to send to the column. See the flexigrid/columns
    #   documentation for usage.
    # ==== Examples
    # The most basic usage to set columns that are displayed by default
    # # @g.columns "first_name, last_name, email, phone_number"
    # Columns that are hidden by default, but may be shown by the user
    # # @g.columns "ssn, address_1, amount", :hidden => true
    # Formatting columns
    # # @g.columns "amount, balance", :format => :currency
    # # @g.columns "active", :format => :boolean, :format_options => :image
    # Using nested column attributes and custom field names
    # # @g.columns "user.first_name, user.last_name, user.address.address_1:Address"
    def columns(cols, options = {})
      if cols.is_a? Array
        cols.each.map{|c| columns(c.first, c.count >= 2 ? c.second : {}) if c.is_a? Array }
        return
      end
      cols.split(/,\s/).each do |col|
        n = col.split(':')
        id = n.first
        name = n.count > 1 ? n.second : nil
        search = col_by_id id
        tmp = search.nil? ? Flexigrid::Column.new(self, id, name) : search
        options.map{|key,value| tmp.send(key.to_s + "=",value)}
        tmp.update!
        @columns << tmp
        @columns_hash[tmp.id] = tmp
      end
    end
    
    # Alias for columns
    def cols(cols, options = {})
      columns cols, options
    end
    
    # Returns an array of cols w/ ID's
    def cols_array
      arr = Array.new
      @columns_hash.each{|k,v| arr << k}
      return arr
    end
    
    # Returns a column object by ID. Might return nil if the column does not exist.
    # ==== Parameters
    # * +id+ - the ID of the column, as defined by the method columns. This can be
    #   either a String or Symbol (it's converted to a String either way)
    # * +raise_on_nil+ - if true, an error will be raised if the column is not found.
    #   defaults to false, which simply returns nil if the column is not found.
    def col_by_id(id, raise_on_nil = false)
      c = @columns_hash[id.to_s]
      raise "Column ID `#{id}` was requested, however it was not defined by method 'columns'" if raise_on_nil and c.nil?
      return c
    end
    
    # Sets a formatter for a given column.
    # ==== Parameters
    # * +id+ - the ID of the column. Raises an exception if not found
    # * +value+ - the name of the formatter
    # * +options+ - any options to pass to it
    def format(id, value, options = {})
      id.split(/,\s/).each do |i|
        col = col_by_id i, true
        col.format = value
        col.format_options = options
      end
    end
    
    # Gets an SQL sort query based upon the current cookie value. If the current
    # cookie value is a column that does not exist, then no sorting is done.
    # Otherwise, the specified column is sorted.
    # == Example Return
    #   `users`.`first_name` DESC
    def get_sort_query
      c = get_cookie 'sort'
      if c.blank?
        if @default_sort.blank?
          c = @columns.first.id
        else
          c = @default_sort
        end
      end
      sp = c.split ' '
      ord = sp.second.blank? ? 'asc' : sp.second.downcase
      col = col_by_id sp.first
      @sort = @columns.first
      return nil if c.nil? or col.nil? or !col.sortable?
      @sort = col
      order = (ord == 'desc' ? 'DESC' : 'ASC')
      col.sort_order = order
      return col.db_fullname + " " + order
    end
    
    def get_select_query
      return nil unless @auto_select
      query = "`#{@model.table_name}`.`id`"
      get_all_sorted_columns.each do |col|
        query += ", #{col.db_fullname}"
      end
      return query
    end
    
    # Set the column to sort by
    # == Parameters
    # * +col_id+ - The ID of the column to sort by
    # * +asc+ - Whether to sort by ASC (true) or DESC (false)
    def set_sort(col_id, asc = true)
      c = col_by_id col_id
      return false if c.blank?
      set_cookie 'sort', "#{c.id} " + (asc ? 'asc' : 'desc')
      return true
    end
    
    # Gets all hidden columns
    def get_hidden_columns
      @hidden_columns_cache = @columns - get_visible_columns if @hidden_columns_cache.nil?
      @hidden_columns_cache
    end
    
    
    # Gets all visible columns based upon cookies. This does of course check to
    # ensure that the columns are indeed valid columns to prevent SQL injections.
    def get_visible_columns
      return @visible_columns_cache unless @visible_columns_cache.nil?
      if get_cookie('columns').nil? or @reload
        visible = ''
        @columns.each do |c|
          next if c.hidden?
          c.visible = true
          visible << c.id.to_s << (c != @columns.last ? ', ' : '')
        end
        set_cookie('columns', visible)
      end
      colstr = get_cookie('columns')
      ret = Array.new
      col_s = colstr.split(/,\s/)
      col_s.each do |c|
        t = col_by_id c
        next if t.blank?
        t.visible = true
        ret << t
      end
      @visible_columns_cache = ret
      return ret
    end
    
    # Gets a list of all columns in the correct order to be sorted.
    def get_all_sorted_columns
      @all_cols_cache = get_visible_columns + get_hidden_columns if @all_cols_cache.nil?
      return @all_cols_cache
    end
    
    # Gets a value of a cookie, with an optional value
    def get_cookie(name, default = nil)
      raise "FlexiGrid cannot access cookie information. Try grid.cookies = cookies in either the controller or view code" if @cookies.blank?
      val = @cookies["flexi_#{@id}_#{name}"]
      # puts "Getting cookie " + "flexi_#{@id}_#{name}"
      return val.blank? ? default : val
    end
    
    # Sets a cookie with a given value
    def set_cookie(name, value)
      @cookies["flexi_#{@id}_#{name}"] = value
      return value
    end
    
    # Whether this grid is using ajax. Ajax is not implemented, so don't worry about
    # this
    def ajax?
      return @ajax
    end
    
    # Converts this grid to an ordered hash of id => name values
    def to_h
      ret = ActiveSupport::OrderedHash.new
      get_all_sorted_columns.each{|col| ret[col.id] = col.name }
      return ret
    end
    
    # Exports the current view to a CSV file. You need to specify a cookies object
    # to use. Options does nothing at the moment
    def to_csv(params, cookies,  options = {})
      @cookies = cookies
      @id = "#{params[:controller]}_#{params[:action]}_#{model_class.name}" if @id.blank?
      
      before_csv_render
      
      return CSV.generate do |csv|
        tmp = []
        get_visible_columns.each do |col|
          tmp << col.name
        end
        csv << tmp
        @model.each do |mdl|
          tmp = []
          get_visible_columns.each do |col|
            tmp << Misc::nested_send(mdl, col.id)
          end
          csv << tmp
        end
      end
    end
  end
end
