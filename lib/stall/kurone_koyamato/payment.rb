# frozen_string_literal: true

module Stall
  module KuroneKoyamato
    # Payment class for Kurone Koyamato
    class Payment < Stall::KuroneKoyamato::PaymentSettings
      TRS_MAP_FIXED_VALUE = 'V_W02'
      CREDIT_CARD_PAYMENT_METHOD = 0
      ONE_TIME_PAYMENT_SERVICE_CODE = '00'

      cattr_accessor  :trader_code,
                      :access_key,
                      :trs_map,
                      :success_url,
                      :failure_url,
                      :cancel_url,
                      :return_url,
                      :cycle_unit,
                      :cycle_interval,
                      :cycle_day,
                      :target_url,
                      :payment_method,
                      :option_service_code

      attr_accessor :date, 
                    :montant, 
                    :settle_price,
                    :order_no,
                    :goods_name,
                    :buyer_name_kana,
                    :buyer_name_kanji,
                    :buyer_tel,
                    :buyer_email,
                    :option_service_code

      # Override constructor to avoid loading a YAML file and use gateway's dynamic
      # configuration instead
      #
      def initialize(gateway, parse_urls: false)
        @@access_key             = gateway.access_key
        @@trader_code            = gateway.trader_code
        # 0 is for credit card payments
        @@payment_method         = CREDIT_CARD_PAYMENT_METHOD
        @@trs_map                = TRS_MAP_FIXED_VALUE
        @@option_service_code    = ONE_TIME_PAYMENT_SERVICE_CODE

        @@cycle_unit = 0
        @@cycle_interval = 1
        @@cycle_day = 30

        # Handle initialization from gateway class and not a gateway instance
        if parse_urls
          @@target_url     = gateway.target_url
          @@cancel_url     = gateway.payment_urls.payment_failure_return_url
          @@success_url  = gateway.payment_urls.payment_success_return_url
          @@failure_url = gateway.payment_urls.payment_failure_return_url
          @@return_url = gateway.payment_urls.payment_notification_url
        end
      end

      def request(payment)
        params = load_params(payment)

        @settle_price = params[:settle_price]
        @order_no   = params[:order_no]
        @goods_name = params[:goods_name]

        @buyer_tel = params[:buyer_tel]
        @buyer_email = params[:buyer_email]
        @buyer_name_kana = params[:buyer_name_kana]
        @buyer_name_kanji = params[:buyer_name_kanji]
        @scheduled_shipping_date = params[:scheduled_shipping_date]

        self
      end

      def response(params)
        p ''
        p '______________________________________________________________________________'
        p ''
        p params
        case params['settle_result']
        when '0'
          params.update(success: false)
        when '1'
          params.update(success: true)
        else
          params.update(success: false)
        end
      end

      # Override this method to avoid implicit "EUR" currency appending
      def required_params(payment)
        @settings ||= {}

        [:settle_price, :order_no, :goods_name, :buyer_name_kanji].each do |key|
          if (value = payment[key])
            @settings.update(key => value)
          else
            raise "KuronePayment error ! Missing required parameter :#{ key }"
          end
        end
      end

      def optionnal_params(payment)
        @settings ||= {}
        @settings.update(buyer_tel: (payment[:buyer_tel] || ''))
        @settings.update(buyer_email: (payment[:buyer_email] || ''))
        @settings.update(buyer_name_kana: (payment[:buyer_name_kana] || ''))
      end

      # Used for recurring purchases only
      def checksum
        Digest::SHA256.hexdigest("#{@@member_id}#{@@authentication_key}#{@@member_id}")
      end

      # Used for recurring purchases only
      def scheduled_shipping_date
        (Time.zone.now + 2.weeks).strftime(date_format)
      end

      protected

      # Used for recurring purchases only
      def date_format
        '%Y%m%d'
      end
    end
  end
end
