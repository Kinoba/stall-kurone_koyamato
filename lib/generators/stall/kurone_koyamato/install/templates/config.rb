# kurone-koyamato payment gateway configuration
# Fill in the informations provided by your kurone-koyamato provider
#
config.payment.kurone_koyamato do |kurone|
  # Trader code given by Kurone Koyamato
  kurone.trader_code = ENV['KURONE_TRADER_CODE']

  # Test or production mode, default to false, changes the payment
  # gateway target URL
  #
  # By default, the test mode is activated in all environments but you just
  # need to add `KURONE_KOYAMATO_PRODUCTION_MODE=true` in your environment variables
  # and restart your server to switch to production mode
  #
  kurone.test_mode = ENV['KURONE_KOYAMATO_PRODUCTION_MODE'] == 'true'
end
