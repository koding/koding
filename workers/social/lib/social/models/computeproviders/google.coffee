ProviderInterface = require './providerinterface'

module.exports = class Google extends ProviderInterface

  @ping = (client, callback)->
    callback null, "Google. #{ client.connection.delegate.profile.nickname }!"


  @create = (client, options, callback)->

    { credential, name } = options

    @fetchCredentialData credential, (err, credential)->

      return callback err  if err?

      meta = {
        "type": "googlecompute",
        "bucket_name": "my-project-packer-images",
        "client_secrets_file": credential.clientSecretsContent,
        "private_key_file": credential.privateKeyContent,
        "project_id": credential.projectId,
        "source_image": "debian-7-wheezy-v20131014",
        "zone": "us-central1-a"
      }

      callback null, { meta }

  @fetchAvailable = (client, options, callback)->

    callback null, [
      {
        name  : "n1-standard-1"
        title : "N1 Standard 1"
        spec  : {
          cpu : 1, ram: 3.75, storage: "n/a"
        }
        price : "$0.070 per Hour"
      }
      {
        name  : "n1-standard-2"
        title : "N1 Standard 2"
        spec  : {
          cpu : 2, ram: 7.5, storage: "n/a"
        }
        price : "$0.140 per Hour"
      }
      {
        name  : "n1-standard-4"
        title : "N1 Standard 4"
        spec  : {
          cpu : 4, ram: 15, storage: "n/a"
        }
        price : "$0.280 per Hour"
      }
      {
        name  : "n1-standard-8"
        title : "N1 Standard 8"
        spec  : {
          cpu : 8, ram: 30, storage: "n/a"
        }
        price : "$0.560 per Hour"
      }
      {
        name  : "n1-highmem-2"
        title : "N1 Highmem 2"
        spec  : {
          cpu : 2, ram: 13, storage: "n/a"
        }
        price : "$0.164 per Hour"
      }
      {
        name  : "n1-highmem-4"
        title : "N1 Highmem 4"
        spec  : {
          cpu : 4, ram: 26, storage: "n/a"
        }
        price : "$0.328 per Hour"
      }
      {
        name  : "n1-highmem-8"
        title : "N1 Highmem 8"
        spec  : {
          cpu : 8, ram: 52, storage: "n/a"
        }
        price : "$0.656 per Hour"
      }

    ]
