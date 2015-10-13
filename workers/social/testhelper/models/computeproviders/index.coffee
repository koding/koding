{ daisy
  expect
  withConvertedUser
  generateRandomEmail
  generateRandomString } = require '../../index'

JCredential = require '../../../lib/social/models/computeproviders/credential'


populateMetaData = (provider) ->

  meta = switch provider

    when 'google'
      projectId            : generateRandomString()
      privateKeyContent    : generateRandomString()
      clientSecretsContent : generateRandomString()

    when 'aws'
      region               : 'us-east-1'
      instance_type        : 't2.micro'
      storage_size         : 2


withConvertedUserAndCredential = (opts, callback) ->

  data   = {}
  client = null

  queue = [

    ->
      withConvertedUser opts, (data_) ->
        data = data_
        queue.next()

    ->
      opts.meta  ?= populateMetaData opts.provider
      opts.title ?= "test#{opts.provider}#{generateRandomString()}"

      JCredential.create data.client, opts, (err, credential) ->

        expect(err).to.not.exist
        data.credential = credential
        queue.next()

    -> callback data

  ]

  daisy queue


module.exports = {
  withConvertedUserAndCredential
}
