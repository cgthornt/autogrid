module Autogrid
  class Hooks
    def self.init

      # Action Controller
      ActiveSupport.on_load(:action_controller) do
        require 'autogrid/rails_hooks/action_controller_extension'
        ::ActionController::Base.send :include, Autogrid::ActionControllerExtension
      end
      
      # Action View
      ActiveSupport.on_load(:action_view) do
        require 'autogrid/rails_hooks/action_view_extension'
        ::ActionView::Base.send :include, Autogrid::ActionViewExtension
      end
    end
  end
end
