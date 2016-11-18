Google      = require './google'
JCredential = require './credential'

{ expect
  withConvertedUser
  generateRandomString
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

    describe 'when data is provided', ->

      it 'should create default meta data', (done) ->

        withConvertedUser ({ client }) ->

          options =
            type          : 'google'
            label         : generateRandomString()
            region        : 'us-central1-a'
            instance_type : 'f1-micro'
            storage_size  : 16

          Google.create client, options, (err, data) ->

            expect(err).to.not.exist
            expect(data.meta.type).to.be.equal(options.type)
            expect(data.meta.assignedLabel).to.be.equal(options.label)
            expect(data.meta.region).to.be.equal(options.region)
            expect(data.meta.instance_type).to.be.equal(options.instance_type)
            expect(data.meta.storage_size).to.be.equal(options.storage_size)

            done()



    describe 'when data is not provided', ->

      it 'should set some of the default values', (done) ->

        client  = null
        options = {}

        Google.create client, options, (err, data) ->

          expect(err).to.not.exist

          { meta } = data
          expect(err).to.not.exist
          expect(meta.type).to.be.equal('google')
          expect(meta.region).to.be.equal('us-central1-a')
          expect(meta.instance_type).to.be.equal('f1-micro')
          expect(meta.storage_size).to.be.equal(8)

          done()


afterTests = -> after removeGeneratedCredentials

beforeTests()

runTests()

afterTests()
