  # CM-CIC payment gateway configuration
  # Fill in the informations provided by your CM or CIC provider
  #
  config.payment.cmcic do |cmcic|
    # Hmac key calculated with the js calculator given by CIC
    cmcic.hmac_key = ENV['CMCIC_HMAC_KEY']
    # TPE number
    cmcic.tpe = ENV['CMCIC_TPE']
    # Merchant name
    cmcic.societe = ENV['CMCIC_SOCIETE']

    # Test or production mode, default to false, changes the payment
    # gateway target URL
    #
    # By default, the test mode is activated in all environments but you just
    # need to add `CMCIC_PRODUCTION_MODE=true` in your environment variables
    # and restart your server to switch to production mode
    #
    cmcic.test_mode = ENV['CMCIC_PRODUCTION_MODE'] == 'true'
  end

