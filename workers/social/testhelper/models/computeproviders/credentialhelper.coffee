{ async
  expect
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

    when 'custom', 'userInput' then {}

    else 'unimplemented provider'

  return meta


CREDENTIALS = {}


createCredential = (client, options, callback) ->

  options.provider ?= 'aws'
  options.meta     ?= generateMetaData options.provider
  options.title    ?= 'koding'

  maxTry = 3
  do create = ->
    JCredential.create client, options, (err, credential) ->
      return create()  if err?.description is 'not logged in' and maxTry--
      addToRemoveList client, credential.identifier  if credential
      console.error 'createCredential:', err  if err
      callback err, { credential }


withConvertedUserAndCredential = (options, callback) ->

  [options, callback] = [callback, options]  unless callback
  options            ?= {}

  withConvertedUser options, (data) ->
    { client } = data

    createCredential client, options, (err, { credential }) ->
      console.error 'withConvertedUserAndCredential:', err  if err
      expect(err).to.not.exist
      data.credential = credential
      callback data


removeGeneratedCredentials = (callback) ->

  CredentialStore = require '../../../lib/social/models/computeproviders/credentialstore'

  queue = [ ]

  (Object.keys CREDENTIALS).forEach (identifier) -> queue.push (next) ->
    CredentialStore.remove CREDENTIALS[identifier], identifier, (err) ->
      expect(err).to.not.exist
      next()

  async.series queue, callback


addToRemoveList = (client, identifier) ->

  CREDENTIALS[identifier] = client


module.exports = {
  addToRemoveList
  createCredential
  generateMetaData
  removeGeneratedCredentials
  withConvertedUserAndCredential
}
