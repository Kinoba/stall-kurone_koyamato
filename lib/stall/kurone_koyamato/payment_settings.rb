# frozen_string_literal: true

module Stall
  module KuroneKoyamato
    class PaymentSettings
      def initialize
        @settings = {}
      end

      def load_settings
        load_yaml_config
      end

      def load_params(payment)
        required_params(payment)
        optionnal_params(payment)
      end

      private

      def optionnal_params(payment)
        @settings ||= {}
        @settings.update(:texte_libre => (payment[:texte_libre] || ""))
        @settings.update(:lgue        => (payment[:lgue]        || "FR"))
        @settings.update(:mail        => (payment[:mail]       || ""))
      end

      # This method is never called because overriden in payment.rb
      def required_params(payment)
        @settings ||= {}

        if payment[:montant]
          @settings.update(:montant => ("%.2f" % payment[:montant]) + "EUR")
        else
          raise "CicPayment error ! Missing required parameter :montant"
        end

        if payment[:reference]
          @settings.update(:reference => payment[:reference])
        else
          raise "CicPayment error ! Missing required parameter :reference"
        end

      end

      def load_yaml_config
        @settings ||= {}

        path = Rails.root.join('config', 'cic_payment.yml')

        if File.exist?(path)
          config = YAML::load(ERB.new(File.read(path)).result)
        else
          raise "File config/cic_payment.yml does not exist"
        end

        env = Rails.env

        unless config[env]
          raise "config/cic_payment.yml is missing a section for `#{env}`"
        end

        settings = {
          :tpe            => config[env]['tpe'],
          :version        => config[env]['version'],
          :societe        => config[env]['societe'],
          :hmac_key       => config[env]['hmac_key'],
          :target_url     => config[env]['target_url']
        }

        %i(url_retour url_retour_ok url_retour_err).each do |k|
          provided_setting_for_key = config[env][k.to_s]

          if provided_setting_for_key.is_a? Hash
            merged_setting_for_key = provided_setting_for_key.merge!(Rails.application.config.payments.default_url_options)
            
            settings[k] =  Rails.application.routes.url_helpers.url_for(merged_setting_for_key)
          else
            settings[k] = provided_setting_for_key
          end
        end

        settings.each do |key, value|
          if value
            @settings.update(key => value)
          else
            raise "CicPayment error ! Missing parameter :#{key} in /config/cic_payment.yml config file"
          end
        end
      end
    end
  end
end