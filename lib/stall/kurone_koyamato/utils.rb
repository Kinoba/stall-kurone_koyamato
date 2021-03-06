# frozen_string_literal: true

module Stall
  module KuroneKoyamato
    module Utils
      protected

      def price_with_currency(price)
        [
          price.format(symbol: '', separator: '.', delimiter: ''),
          currency
        ].join
      end
    end
  end
end
