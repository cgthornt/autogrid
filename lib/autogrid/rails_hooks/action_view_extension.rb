module Autogrid
  module ActionViewExtension
    
    # Allows the autogrid to be rendered via html
    def render_autogrid(table, *args, &block)
      
      # Pass the ActionView to the table and update any options
      table.view = self
      table.update_options(*args)
      
      # Call the block
      if block_given?
        block.call(table)
      end
      table.to_html
    end
  end
end
