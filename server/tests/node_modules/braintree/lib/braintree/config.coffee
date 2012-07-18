class Config
  constructor: (rawConfig) ->
    @apiVersion = '2'
    @environment = rawConfig.environment
    @merchantId = rawConfig.merchantId
    @publicKey = rawConfig.publicKey
    @privateKey = rawConfig.privateKey
    @baseMerchantPath = "/merchants/#{rawConfig.merchantId}"

exports.Config = Config
