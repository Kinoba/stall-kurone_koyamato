module Stall
  module Cmcic
    class Gateway < Stall::Payments::Gateway
      register :cmcic

      # Hmac key calculated with the js calculator given by CIC
      class_attribute :hmac_key
      # TPE number
      class_attribute :tpe
      # Merchant name
      class_attribute :societe

      # Test or production mode, default to false, changes the payment
      # gateway target URL
      class_attribute :test_mode
      self.test_mode = !Rails.env.production?

      # Remote API version, should not change any time soon ...
      class_attribute :version
      self.version = "3.0"

      def self.request(cart)
        Request.new(cart)
      end

      def self.response(request)
        Response.new(request)
      end

      def self.fake_payment_notification_for(cart)
        Stall::Cmcic::FakeGatewayPaymentNotification.new(cart)
      end

      def target_url
        if test_mode
          "https://paiement.creditmutuel.fr/test/paiement.cgi"
        else
          "https://paiement.creditmutuel.fr/paiement.cgi"
        end
      end

      class Request
        include Stall::Cmcic::Utils

        attr_reader :cart

        delegate :currency, to: :cart, allow_nil: true

        def initialize(cart)
          @cart = cart
        end

        def payment_form_partial_path
          'stall/cmcic/payment_form'
        end

        def params
          @params ||= Stall::Cmcic::CicPayment.new(gateway, parse_urls: true).request(
            montant: price_with_currency(cart.total_price),
            reference: gateway.transaction_id,
            texte_libre: cart.reference
          )
        end

        def gateway
          @gateway = Stall::Cmcic::Gateway.new(cart)
        end
      end

      class Response
        attr_reader :request

        def initialize(request)
          @request = request
        end

        def valid?
          response.length > 1
        end

        def success?
          response[:success]
        end

        def process
          valid? && success?
        end

        def rendering_options
          { text: "version=2\ncdr=#{ return_code }\n" }
        end

        def cart
          @cart ||= ProductList.find_by_reference(response['texte-libre'])
        end

        def gateway
          @gateway = Stall::Cmcic::Gateway
        end

        private

        def response
          @response ||= Stall::Cmcic::CicPayment.new(gateway).response(
            Rack::Utils.parse_nested_query(request.raw_post)
          )
        end

        def return_code
          if success? || (response['code-retour'].try(:downcase) == 'annulation')
            '0'
          else
            '1'
          end
        end
      end
    end
  end
end
