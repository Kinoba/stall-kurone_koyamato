module Stall
  module KuroneKoyamato
    class FakeGatewayPaymentNotification < Stall::Payments::FakeGatewayPaymentNotification
      include Stall::KuroneKoyamato::Utils

      delegate :currency, to: :cart

      def params
        {}.tap do |params|
          params.merge!(options)
          params['MAC'] = bank_mac_key
        end
      end

      private

      def format_date(date)
        date.strftime("%d/%m/%Y_a_%H:%M:%S")
      end

      def options
        @options ||= {
          'TRS_MAP' => 'V_W02',
          'date' => format_date(Time.now),
          'montant' => price_with_currency(cart.total_price),
          'reference' => transaction_id,
          'texte-libre' => cart.reference,
          'code-retour' => "payetest",
          'cvx' => "oui",
          'vld' => "1219",
          'brand' => "na",
          'status3ds' => "-1",
          'numauto' => 'xxxx',
          'motifrefus' => "",
          'originecb' => "00x",
          'bincb' => "000001",
          'hpancb' => "F6FBF44A7EC30941DA2E411AA8A50C77F174B2BB",
          'ipclient' => "01.01.01.01",
          'originetr' => "FRA",
          'veres' => "",
          'pares' => "",
          'modepaiement' => "CB"
        }
      end

      def bank_mac_key
        @bank_mac_key ||= kurone_payment.response_mac(options)
      end

      def kurone_payment
        @kurone_payment ||= Stall::KuroneKoyamato::Payment.new(gateway)
      end
    end
  end
end
