require 'autogrid/classes/table'

module Autogrid
  module ActionControllerExtension
    
    def autogrid(*args, &block)
      table = Autogrid::Table.new(*args)
      table.cookies = cookies
      table.session = session
      block.call(table) if block_given?
      return table
    end

  end
end
