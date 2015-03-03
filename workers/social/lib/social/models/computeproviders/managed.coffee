
ProviderInterface = require './providerinterface'

module.exports = class Managed extends ProviderInterface

  @ping = (client, options, callback)->

    callback null, "Managed VMs rulez #{ client.r.account.profile.nickname }!"
