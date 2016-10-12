Google      = require './google'
JCredential = require './credential'

{ expect
  withConvertedUser
  checkBongoConnectivity }      = require '../../../../testhelper'
{ removeGeneratedCredentials
  withConvertedUserAndCredential } = require '../../../../testhelper/models/computeproviders/credentialhelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.google', ->

  describe '#ping()', ->

    it 'should reply to ping request', (done) ->

      withConvertedUser ({ client, account }) ->
        Google.ping client, (err, data) ->
          expect(err?.message).to.not.exist
          expect(data).to.be.equal "Google. #{account.profile.nickname}!"
          done()


  describe '#create()', ->

    describe 'when credential is provided', ->

      it 'should create default meta data', (done) ->

        withConvertedUserAndCredential { provider : 'google' }, (data) ->

          { credential, client } = data
          { clientSecretsContent, privateKeyContent, projectId } = credential

          Google.create client, data, (err, data) ->
            expect(err).to.not.exist

            { meta } = data
            expect(meta.type)                 .to.be.equal 'googlecompute'
            expect(meta.bucket_name)          .to.be.equal 'my-project-packer-images'
            expect(meta.client_secrets_file)  .to.be.equal clientSecretsContent
            expect(meta.private_key_file)     .to.be.equal privateKeyContent
            expect(meta.project_id)           .to.be.equal projectId
            expect(meta.source_image)         .to.be.equal 'debian-7-wheezy-v20131014'
            expect(meta.zone)                 .to.be.equal 'us-central1-a'
            done()



    describe 'when credential is not provided', ->

      it 'should set some of the default values', (done) ->

        client  = null
        options = {}

        Google.create client, options, (err, data) ->
          expect(err).to.not.exist

          { meta } = data
          expect(meta.type)                 .to.be.equal 'googlecompute'
          expect(meta.bucket_name)          .to.be.equal 'my-project-packer-images'
          expect(meta.client_secrets_file)  .to.not.exist
          expect(meta.private_key_file)     .to.not.exist
          expect(meta.project_id)           .to.not.exist
          expect(meta.source_image)         .to.be.equal 'debian-7-wheezy-v20131014'
          expect(meta.zone)                 .to.be.equal 'us-central1-a'
          done()


afterTests = -> after removeGeneratedCredentials

beforeTests()

runTests()

afterTests()
