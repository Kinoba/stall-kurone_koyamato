module Stall
  module Cmcic
    class CicPayment < ::CicPayment
      # Override constructor to avoid loading a YAML file and use gateway's dynamic
      # configuration instead
      #
      def initialize(gateway, parse_urls: false)
        @@tpe            = gateway.tpe
        @@version        = gateway.version
        @@societe        = gateway.societe
        @@hmac_key       = gateway.hmac_key

        # Handle initialization from gateway class and not a gateway instance
        if parse_urls
          @@target_url     = gateway.target_url
          @@url_retour     = gateway.payment_urls.payment_failure_return_url
          @@url_retour_ok  = gateway.payment_urls.payment_success_return_url
          @@url_retour_err = gateway.payment_urls.payment_failure_return_url
        end
      end

      # Override this method to avoid implicit "EUR" currency appending
      def required_params(payment)
        @settings ||= {}

        [:montant, :reference].each do |key|
          if (value = payment[key])
            @settings.update(key => value)
          else
            raise "CicPayment error ! Missing required parameter :#{ key }"
          end
        end
      end
    end
  end
end
