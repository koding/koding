ProviderInterface = require './providerinterface'

module.exports = class Amazon extends ProviderInterface

  @ping = (client, options, callback)->
    callback null, "AWS RULEZ #{ client.r.account.profile.nickname }!"

  @create = (client, options, callback)->

    { credential, name } = options

    @fetchCredentialData credential, (err, credential)->

      return callback err  if err?

      callback null,
        {
          "variables": {
            "aws_access_key": credential.accessKeyId
            "aws_secret_key": credential.secretAccessKey
          },
          "builders": [{
            "type": "amazon-ebs",
            "access_key": "{{user `aws_access_key`}}",
            "secret_key": "{{user `aws_secret_key`}}",
            "region": credential.region,
            "source_ami": "ami-de0d9eb7",
            "instance_type": name,
            "ssh_username": "ubuntu",
            "ami_name": "packer-example {{timestamp}}"
          }]
        }

  @fetchAvailable = (client, options, callback)->

    callback null, [
      {
        name  : "m3.medium"
        title : "M3 medium"
        spec  : {
          cpu : 1, ram: 3.75, storage: 4
        }
        price : "$0.070 per Hour"
      }
      {
        name  : "m3.large"
        title : "M3 large"
        spec  : {
          cpu : 2, ram: 7.5, storage: 32
        }
        price : "$0.140 per Hour"
      }
      {
        name  : "m3.xlarge"
        title : "M3 xlarge"
        spec  : {
          cpu : 4, ram: 15, storage: 80
        }
        price : "$0.280 per Hour"
      }
      {
        name  : "m3.2xlarge"
        title : "M3 2xlarge"
        spec  : {
          cpu : 8, ram: 30, storage: 160
        }
        price : "$0.560 per Hour"
      }
    ]
