# frozen_string_literal: true

module Stall
  module KuroneKoyamato
    # Payment class for Kurone Koyamato
    class Payment < Stall::KuroneKoyamato::PaymentSettings
      TRS_MAP_FIXED_VALUE = 'V_W02'
      CREDIT_CARD_PAYMENT_METHOD = 0
      ONE_TIME_PAYMENT = 0

      cattr_accessor  :version,
                      :hmac_key,
                      :trader_code,
                      :societe,
                      :access_key,
                      :authentication_key,
                      :trs_map,
                      :member_id,
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
                    :buyer_name,
                    :buyer_name_kanji,
                    :buyer_tel,
                    :buyer_email,
                    :option_service_code

      @@access_key             = ''
      @@authentication_key     = ''
      @@member_id              = ''
      @@trader_code            = ''
      @@target_url             = ''
      @@return_url             = ''
      @@payment_method         = ''
      @@trs_map                = ''
      @@option_service_code    = ''
      @@cycle_unit             = ''
      @@cycle_interval         = ''
      @@cycle_day              = ''

      # Override constructor to avoid loading a YAML file and use gateway's dynamic
      # configuration instead
      #
      def initialize(gateway, parse_urls: false)
        @@access_key             = gateway.access_key
        @@authentication_key     = gateway.authentication_key
        @@member_id              = gateway.member_id
        @@trader_code            = gateway.trader_code
        # 0 is for credit card payments
        @@payment_method         = CREDIT_CARD_PAYMENT_METHOD
        @@trs_map                = TRS_MAP_FIXED_VALUE
        @@option_service_code    = ONE_TIME_PAYMENT

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
        @buyer_name = params[:buyer_name]
        @buyer_name_kanji = params[:buyer_name_kanji]
        @scheduled_shipping_date = params[:scheduled_shipping_date]

        self
      end

      def response(params)
        if verify_hmac(params)
          case params['code-retour']
          when "Annulation"
            params.update(:success => false)
          when "payetest", "paiement"
            params.update(:success => true)
          else
            params.update(:success => false)
          end
        else
          params.update(:success => false)
        end
      end

      # Override this method to avoid implicit "EUR" currency appending
      def required_params(payment)
        @settings ||= {}

        [:settle_price, :order_no, :goods_name].each do |key|
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
        @settings.update(buyer_name: (payment[:buyer_name] || ''))
        @settings.update(buyer_name_kanji: (payment[:buyer_name_kanji] || ''))
        @settings.update(scheduled_shipping_date: (payment[:scheduled_shipping_date] || scheduled_shipping_date))
      end
      
      def checksum
        Digest::SHA256.hexdigest("#{@@member_id}#{@@authentication_key}#{@@member_id}")
      end
      
      def scheduled_shipping_date
        (Time.zone.now + 2.weeks).strftime(date_format)
      end
      
      # === response_mac(params)
      # This function is used to verify that the sent MAC by CIC is the one expected.
      # It calculates the hmac from the correct chain of params. 
      # 
      # The HMAC returned by the bank uses this chain: 
      # <TPE>*<date>*<montant>*<reference>*<texte-libre>*3.0*<code-retour>*
      # <cvx>*<vld>*<brand>*<status3ds>*<numauto>*<motifrefus>*<originecb>*
      # <bincb>*<hpancb>*<ipclient>*<originetr>*<veres>*<pares>*
      #
      # Here is an example of the parameters sent back by the CIC payment module:
      #   Parameters: {"TPE"=>"012345", "date"=>"01/01/2011_a_00:00:00", "montant"=>"10.00EUR", "reference"=>"12_unique_caracters_string", 
      #     "MAC"=>"CalculatedMAC by the bank", 
      #     "texte-libre"=>"{\"custom_id\":1,\"user_id\":1,\"text\":\"Your text\"}", 
      #     "code-retour"=>"payetest", "cvx"=>"oui", "vld"=>"1219", "brand"=>"na", "status3ds"=>"-1", 
      #     "motifrefus"=>"", "originecb"=>"00x", "bincb"=>"000001", "hpancb"=>"F6FBF44A7EC30941DA2E411AA8A50C77F174B2BB", 
      #     "ipclient"=>"01.01.01.01", "originetr"=>"FRA", "veres"=>"", "pares"=>"", "modepaiement"=>"CB"}
      #
      # You can also Use this function for your tests to simulate an exchange with the bank.
      def response_mac params
        
        chain = [
          self.tpe, params['date'], params['montant'], params['reference'], params['texte-libre'], self.version, params['code-retour'], 
          params['cvx'], params['vld'], params['brand'], params['status3ds'], params["numauto"], params['motifrefus'], params['originecb'], 
          params['bincb'], params['hpancb'], params['ipclient'], params['originetr'], params['veres'], params['pares'], ""
        ].join('*')
        
        hmac_token(false, chain)
      end

      def verify_hmac params
        params['MAC'] ? hmac = params['MAC'] : hmac = ""

        # Check if the HMAC matches the HMAC of the data string
        response_mac(params).downcase == hmac.downcase
      end

      # Return the HMAC for a data string
      def hmac_token(form_hmac = true, chain = nil)
        # This chain must contains:
        # <TPE>*<date>*<montant>*<reference>*<texte-libre>*<version>*<lgue>*<societe>*<mail>*
        # <nbrech>*<dateech1>*<montantech1>*<dateech2>*<montantech2>*<dateech3>*<montantech3>*
        # <dateech4>*<montantech4>*<options>
        # For a regular payment, it will be somthing like this: 
        # 1234567*05/12/2006:11:55:23*62.73EUR*ABERTYP00145*ExempleTexteLibre*3.0*FR*monSite1*internaute@sonemail.fr**********
        #
        # So the chain array must contains 9 filled elements + 9 unfilled elements + 1 final star
        # <text-libre>, <lgue> and <mail> are optional, but don't forget to put them in the chain if you decide to add
        # them to the form
        #
        # For a fragmented payment: 
        # 1234567*05/12/2006:11:55:23*62.73EUR*ABERTYP00145*ExempleTexteLibre*3.0*FR*monSite1*internaute@sonemail.fr*
        # 4*05/12/2006*16.23EUR*05/01/2007*15.5EUR*05/02/2007*15.5EUR*05/03/2007*15.5EUR*
        if form_hmac && chain.blank?
          chain = [self.tpe,
              self.date,
              self.montant,
              self.reference,
              self.texte_libre,
              self.version,
              self.lgue,
              self.societe,
              self.mail,
              "", "", "", "", "", "", "", "", "", "" # 10 stars: 9 for fragmented unfilled params + 1 final star 
          ].join("*")
        end

        hmac_sha1(usable_key(self.hmac_key), chain).downcase
      end


      protected

      def date_format
        '%Y%m%d'
      end

      def hmac_sha1(key, data)
        length = 64

        if (key.length > length)
          key = [Digest::SHA1.hexdigest(key)].pack("H*")
        end

        key  = key.ljust(length, 0.chr)
        ipad = ''.ljust(length, 54.chr)
        opad = ''.ljust(length, 92.chr)

        k_ipad = compute(key, ipad)
        k_opad = compute(key, opad)

        OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new("sha1"), key, data)
      end

      private

      # Return the key to be used in the hmac method
      def usable_key(hmac_key)
        hex_string_key  = hmac_key[0..37]
        hex_final   = hmac_key[38..40] + "00";

        cca0 = hex_final[0].ord

        if cca0 > 70 && cca0 < 97
          hex_string_key += (cca0 - 23).chr + hex_final[1..2]
        elsif hex_final[1..2] == "M"
          hex_string_key += hex_final[0..1] + "0"
        else
          hex_string_key += hex_final[0..2]
        end

        [hex_string_key].pack("H*")
      end

      def compute(key, pad)
        raise ArgumentError, "Can't bitwise-XOR a String with a non-String" \
          unless pad.kind_of? String
        raise ArgumentError, "Can't bitwise-XOR strings of different length" \
          unless key.length == pad.length

        result = (0..key.length-1).collect { |i| key[i].ord ^ pad[i].ord }
        result.pack("C*")
      end
    end
  end
end
