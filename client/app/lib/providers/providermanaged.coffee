ProviderBaseView = require './providerbaseview'

module.exports = class ProviderManaged extends ProviderBaseView

  PROVIDER = "managed"

  constructor:->
    super
      cssClass    : PROVIDER
      provider    : PROVIDER
    ,
      name        : "Managed"
      description : """
        Managed VMs constructs a bridge between koding and your PC/VM/Machine.
      """
