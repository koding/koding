ProviderInterface = require './providerinterface'

module.exports = class DigitalOcean extends ProviderInterface

  @ping = (client, options, callback)->
    callback null, "DigitalOcean is better #{ client.r.account.profile.nickname }!"

  @create = (client, options, callback)->

    { credential, instanceType, region } = options

    # @fetchCredentialData credential, (err, cred)->
    #   return callback err  if err?

    meta =
      type   : "digitalocean"
      image  : "ubuntu-13-10-x64"
      region : region       ? "sfo1"
      size   : instanceType ? "512mb"

    callback null, { meta, credential }


  @fetchAvailable = (client, options, callback)->

    callback null, [
      {
        name  : "512mb"
        title : "512 MB"
        spec  : {
          cpu : 1, ram: 512, storage: 20, transfer: "1TB"
        }
        price : "$5 per Month"
      }
      {
        name  : "1gb"
        title : "1 GB"
        spec  : {
          cpu : 1, ram: 1024, storage: 30, transfer: "2TB"
        }
        price : "$10 per Month"
      }
      {
        name  : "2gb"
        title : "2 GB"
        spec  : {
          cpu : 2, ram: 2048, storage: 40, transfer: "3TB"
        }
        price : "$20 per Month"
      }
      {
        name  : "4gb"
        title : "4 GB"
        spec  : {
          cpu : 2, ram: 4096, storage: 60, transfer: "4TB"
        }
        price : "$40 per Month"
      }
      {
        name  : "8gb"
        title : "8 GB"
        spec  : {
          cpu : 4, ram: 8192, storage: 80, transfer: "5TB"
        }
        price : "$80 per Month"
      }
    ]
