module Stall
  module Cmcic
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def copy_config_template
        inject_into_file 'config/initializers/stall.rb', after: "Stall.configure do |config|\n" do
          File.read(File.join(self.class.source_root, 'config.rb'))
        end
      end
    end
  end
end
