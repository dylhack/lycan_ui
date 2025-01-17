# frozen_string_literal: true

module LycanUi
  module Generators
    class SetupGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      class InvalidInstallationTypeError < StandardError; end

      def detect_installation_type
        @use_importmap = File.exist?("config/importmap.rb")
        @use_node =  File.exist?("tailwind.config.js")
        @use_sprockets = Object.const_defined?("Sprockets")
      end

      def install_for_type
        install_importmap if @use_importmap

        install_sprockets if @use_sprockets
      end

      def install_assets_path
        return if @use_node

        insert_into_file(
          "config/initializers/assets.rb",
          "Rails.application.config.assets.paths << Rails.root.join(\"app\", \"components\")\n")
        insert_into_file(
          "config/initializers/assets.rb",
          "Rails.application.config.importmap.cache_sweepers << Rails.root.join(\"app\", \"components\")")
      end

      def install_tailwind_config
        if @use_node
          %x(yarn add tailwindcss-animate)

          template("config/node/tailwind.config.js", "tailwind.config.js", force: true)
        else
          template("config/nobuild/tailwind.config.js", "config/tailwind.config.js", force: true)
        end
      end

      def install_gem
        installed_already = File.read("Gemfile").match?("view_component")

        return if installed_already

        %x(bundle add view_component)
      end

      def install_application_component
        empty_directory("app/components")
        copy_file("components/component.rb", "app/components/application_component.rb", force: true)

        copy_file("lib/attributes_helper.rb", "lib/lycan_ui/attributes_helper.rb")
        copy_file("lib/classes_helper.rb", "lib/lycan_ui/classes_helper.rb")
        copy_file("lib/validations_helper.rb", "lib/lycan_ui/validations_helper.rb")
      end

      private

      def install_importmap
        if @use_sprockets
          insert_into_file("config/importmap.rb", <<~RB
              components_path = Rails.root.join('app/components')
              components_path.glob('**/*_controller.js').each do |controller|
                name = controller.relative_path_from(components_path).to_s.remove(/\\.js$/)
                pin "controllers/\#{name}", to: name, preload: false
              end
            RB
          )
        else
          insert_into_file("config/importmap.rb", <<~RB
            components_path = Rails.root.join("app/components")
            components_path.glob("**/*_controller.js").each do |controller|
              name = controller.relative_path_from(components_path).to_s.remove(/\.js$/)
              pin "controllers/#{name}", to: "#{name}.js", preload: false
            end
            RB
          )
        end
      end

      def install_sprockets
        insert_into_file("app/assets/config/manifest.js", "//= link_tree ../../components .js")
      end
    end
  end
end
