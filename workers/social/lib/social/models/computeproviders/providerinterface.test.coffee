ProviderInterface = require './providerinterface'
CredentialStore   = require './credentialstore'

{ async
  expect
  checkBongoConnectivity }         = require '../../../../testhelper'
{ withConvertedUserAndCredential } = require '../../../../testhelper/models/computeproviders/credentialhelper'

CREDENTIALS = []

# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.providerinterface', ->

  describe '#fetchCredentialData()', ->

    it 'it should be able fetch credential data ', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->

        CREDENTIALS.push [client, credential.identifier]

        ProviderInterface.fetchCredentialData client, credential, (err, credData) ->
          expect(err).to.not.exist
          expect(credData).to.be.an 'object'
          expect(credData.meta).to.be.an 'object'
          expect(credData.identifier).to.be.equal credential.identifier
          done()


afterTests = ->

  after (done) ->

    queue = [ ]

    CREDENTIALS.forEach ([client, identifier]) -> queue.push (next) ->
      CredentialStore.remove client, identifier, (err) ->
        expect(err).to.not.exist
        next()

    async.series queue, done


beforeTests()

runTests()

afterTests()
