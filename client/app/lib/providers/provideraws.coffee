ProviderBaseView = require './providerbaseview'

module.exports = class ProviderAws extends ProviderBaseView

  PROVIDER = 'aws'

  constructor:->
    super
      cssClass    : PROVIDER
      provider    : PROVIDER
    ,
      name        : "Aws"
      description : """
        Amazon Web Services offers reliable, scalable, and inexpensive
        cloud computing services. Free to join, pay only for what you use.
      """
