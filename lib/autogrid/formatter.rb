module Autogrid
  module Formatter
    class << self
    
      # TODO: make changeable!
      def boolean(view, value, options = {})
        if options == :image
          return value ? view.image_tag('ui_check.png') : view.image_tag('ui_status_inactive.png') 
        end
        if options == :inverse or options == :reverse
          value = !value
        end
        return value ? 'Yes' : 'No'
      end
      
      def currency(view, value, options = {})
        view.number_to_currency value
      end
    end
  end
end
