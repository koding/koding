{ expect
  withConvertedUser
  generateRandomEmail
  generateRandomString } = require '../../index'

JCredential = require '../../../lib/social/models/computeproviders/credential'


generateMetaData = (provider) ->

  meta = switch provider

    when 'google'
      projectId            : generateRandomString()
      privateKeyContent    : generateRandomString()
      clientSecretsContent : generateRandomString()

    when 'aws'
      region               : 'us-east-1'
      access_key           : generateRandomString()
      secret_key           : generateRandomString()
      storage_size         : 2
      instance_type        : 't2.nano'

    when 'koding'
      type                 : 'aws'
      region               : region ? SUPPORTED_REGIONS[0]
      source_ami           : ''
      instance_type        : 't2.nano'
      storage_size         : storage
      alwaysOn             : no

    else 'unimplemented provider'

  return meta


createCredential = (client, options, callback) ->

  options.provider ?= 'aws'
  options.meta     ?= generateMetaData options.provider
  options.title    ?= 'koding'

  JCredential.create client, options, (err, credential) ->
    callback err, { credential }


withConvertedUserAndCredential = (options, callback) ->

  [options, callback] = [callback, options]  unless callback
  options            ?= {}

  withConvertedUser options, (data) ->
    { client } = data

    createCredential client, options, (err, { credential }) ->
      expect(err).to.not.exist
      data.credential = credential
      callback data


module.exports = {
  createCredential
  generateMetaData
  withConvertedUserAndCredential
}
