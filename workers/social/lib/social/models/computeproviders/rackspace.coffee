ProviderInterface = require './providerinterface'

module.exports = class Rackspace extends ProviderInterface

  @ping = (client, options, callback)->

    callback null, "Rackspace is cool #{ client.r.account.profile.nickname }!"


  @fetchAvailable = (client, options, callback)->

    callback null, [
      {
        name  : "1gb"
        title : "1 GB"
        spec  : {
          cpu : 1, ram: 1, storage: 40, transfer: "2TB"
        }
        price : "$10 per Month"
      }
    ]
