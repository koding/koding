ProviderInterface = require './providerinterface'

module.exports = class DigitalOcean extends ProviderInterface

  @ping = (client, options, callback)->
    callback null, "DigitalOcean is better #{ client.r.account.profile.nickname }!"

  @create = (client, options, callback)->

    { credential, instanceType } = options

    @fetchCredentialData credential, (err, cred)->

      return callback err  if err?

      meta =
        type   : "digitalocean"
        image  : "ubuntu-13-10-x64"
        region : "ams1"
        size   : instanceType ? "512mb"

      callback null, {
        meta, credential: cred.publicKey
      }
