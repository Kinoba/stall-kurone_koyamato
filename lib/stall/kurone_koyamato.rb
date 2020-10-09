# frozen_string_literal: true

require 'stall'

module Stall
  module KuroneKoyamato
    extend ActiveSupport::Autoload

    autoload :Payment
    autoload :Version
    autoload :Utils
    autoload :FakeGatewayPaymentNotification
  end
end

require 'stall/kurone_koyamato/gateway'
require 'stall/kurone_koyamato/engine'
