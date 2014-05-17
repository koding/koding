ProviderInterface = require './providerinterface'

module.exports = class DigitalOcean extends ProviderInterface

  @ping = (client, options, callback)->
    callback null, "DigitalOcean is better #{ client.r.account.profile.nickname }!"

  @fetchExisting = (client, options, callback)->
    callback null, []

  @create = (client, options, callback)->

    { credential, name } = options

    @fetchCredentialData credential, (err, credential)->

      return callback err  if err?

      meta =
        {
          "variables": {
            "do_client_id": credential.clientId ? "",
            "do_api_key": credential.apiKey ? "",
            "klient_deb": "klient_0.0.1_amd64.deb"
          },
          "builders": [
            {
              "type": "digitalocean",
              "client_id": "{{user `do_client_id`}}",
              "api_key": "{{user `do_api_key`}}",
              "image": "ubuntu-13-10-x64",
              "region": "ams1",
              "size": "512mb",
              "snapshot_name": "koding-{{timestamp}}"
            }
          ]
        }

      callback null, { meta }
