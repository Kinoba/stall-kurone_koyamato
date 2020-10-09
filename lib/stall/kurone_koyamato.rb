# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.require(:default, :development, :test)
require 'rails'
require 'haml-rails'
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
