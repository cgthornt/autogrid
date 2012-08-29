module Autogrid
  class Railtie < ::Rails::Railtie
    initializer 'autogrid' do |_app|
      Autogrid::Hooks.init
    end
  end
end
