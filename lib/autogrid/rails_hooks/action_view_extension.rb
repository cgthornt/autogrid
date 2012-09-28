module Autogrid
  module ActionViewExtension
    
    # Displays a grid from a {Flexigrid} object
    # @param [Flexigrid] grid a Flexigrid object
    def autogrid(grid)
      raise TypeError.new "grid must be a Flexigrid object" unless grid.is_a? Flexigrid
      grid.cookies = cookies
      grid.before_render
      render :partial => 'shared/flexigrid/grid', :locals => {
        :grid => grid
      }
    end
  end
end
