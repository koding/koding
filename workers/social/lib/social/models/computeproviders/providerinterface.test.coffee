ProviderInterface = require './providerinterface'

{ expect
  checkBongoConnectivity }         = require '../../../../testhelper'
{ withConvertedUserAndCredential } = require '../../../../testhelper/models/computeproviders/credentialhelper'

# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.providerinterface', ->

  describe '#fetchCredentialData()', ->

    it 'it should be able fetch credential data ', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        ProviderInterface.fetchCredentialData credential, (err, credData) ->
          expect(err).to.not.exist
          expect(credData).to.be.an 'object'
          expect(credData.meta).to.be.an 'object'
          expect(credData.identifier).to.be.equal credential.identifier
          done()



beforeTests()

runTests()

