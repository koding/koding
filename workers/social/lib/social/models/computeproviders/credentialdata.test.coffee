JCredentialData = require './credentialdata'
{ expect }      = require '../../../../testhelper'


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.credentialdata', ->

  describe 'JCredentialData', ->

    it 'should exist', ->
      expect(JCredentialData).to.be.an 'function'
      expect(JCredentialData.set).to.be.an 'function'


runTests()
