# frozen_string_literal: true

module Stall
  module KuroneKoyamato
    class PaymentSettings
      def initialize
        @settings = {}
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
    end
  end
end