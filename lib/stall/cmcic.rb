require 'cic_payment'
require 'stall'

module Stall
  module Cmcic
    extend ActiveSupport::Autoload

    autoload :CicPayment
    autoload :Version
    autoload :Utils
    autoload :FakeGatewayPaymentNotification
  end
end

require 'stall/cmcic/gateway'
require 'stall/cmcic/engine'
