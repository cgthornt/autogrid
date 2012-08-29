require 'autogrid/table'

module Autogrid
  module ActionControllerExtension
    
    def autogrid(record, *args, &block)
      table = Table.new(record, params)
      table.cookies = cookies
      table.session = session
      table.update_options(*args)
      block.call(table) if block_given?
      return table
    end

  end
end
