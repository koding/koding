ProviderInterface = require './providerinterface'

module.exports = class Google extends ProviderInterface

  @providerSlug  = 'google'

  @bootstrapKeys = []

  @sensitiveKeys = ['credentials']


  @ping = (client, callback) ->
    callback null, "Google. #{ client.connection.delegate.profile.nickname }!"


  @create = (client, options, callback) ->

    { credential, name } = options

    @fetchCredentialData client, credential, (err, credential) ->

      return callback err  if err?

      meta = {
        'type': 'googlecompute',
        'bucket_name': 'my-project-packer-images',
        'client_secrets_file': credential.clientSecretsContent,
        'private_key_file': credential.privateKeyContent,
        'project_id': credential.projectId,
        'source_image': 'debian-7-wheezy-v20131014',
        'zone': 'us-central1-a'
      }

      callback null, { meta }
