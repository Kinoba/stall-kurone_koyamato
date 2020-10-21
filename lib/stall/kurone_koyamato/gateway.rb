# frozen_string_literal: true

module Stall
  module KuroneKoyamato
    # Payment gateway for Kurone Koyamato
    class Gateway < Stall::Payments::Gateway
      register :kurone_koyamato

      # Hmac key calculated with the js calculator given by Kurone Koyamato
      class_attribute :trader_code
      class_attribute :access_key
      class_attribute :authentication_key
      class_attribute :member_id

      # Test or production mode, default to false, changes the payment
      # gateway target URL
      class_attribute :test_mode
      self.test_mode = !Rails.env.production?

      # TODO: Not sure what version is yet...
      class_attribute :version
      self.version = '1.0'

      def self.request(cart)
        Request.new(cart)
      end

      def self.response(request)
        Response.new(request)
      end

      def self.fake_payment_notification_for(cart)
        Stall::KuroneKoyamato::FakeGatewayPaymentNotification.new(cart)
      end

      def target_url
        if test_mode
          'https://ptwebcollect.jp/test_gateway/settleSelectAction.gw'
        else
          'https://payment.kuronekoyamato.co.jp/webcollect/settleSelectAction.gw'
        end
      end

      class Request
        include Stall::KuroneKoyamato::Utils

        attr_reader :cart

        delegate :currency, to: :cart, allow_nil: true

        def initialize(cart)
          @cart = cart
        end

        def payment_form_partial_path
          'stall/kurone_koyamato/payment_form'
        end

        def params
          @params ||= Stall::KuroneKoyamato::Payment.new(gateway, parse_urls: true).request(
            settle_price: cart.total_price,
            goods_name: cart.line_items.first.name,
            order_no: gateway.transaction_id.gsub('ESHOP-', ''),
            regular_order_no: cart.reference,
            buyer_tel: cart.customer.shipping_address.phone,
            buyer_email: cart.customer.email,
            buyer_name_kanji: "#{cart.customer.shipping_address.first_name} #{cart.customer.shipping_address.last_name}"
          )
        end

        def gateway
          @gateway = Stall::KuroneKoyamato::Gateway.new(cart)
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
          @cart ||= Cart.find_by_payment_transaction_id("ESHOP-#{response['order_no']}")
        end

        def gateway
          @gateway = Stall::KuroneKoyamato::Gateway
        end

        private

        def response
          @response ||= Stall::KuroneKoyamato::Payment.new(gateway).response(
            Rack::Utils.parse_nested_query(request.raw_post)
          )
        end

        def return_code
          if success? || (response['settle_result'].try(:downcase) == '0')
            '0'
          else
            '1'
          end
        end
      end
    end
  end
end
