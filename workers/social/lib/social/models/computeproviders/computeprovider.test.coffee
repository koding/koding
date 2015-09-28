
{ PLANS, PROVIDERS, fetchGroupStackTemplate, revive,
  fetchUsage, checkTemplateUsage } = require './computeutils'

{ expect
  withConvertedUser
  checkBongoConnectivity
  generateDummyUserFormData } = require '../../../../testhelper'

ComputeProvider = require './computeprovider'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.computeprovider', ->

  describe '#fetchProviders()', ->

    it 'should fetch providers successfully', (done) ->
      
      client = null

      ComputeProvider.fetchProviders client, (err, providers) ->
        expect(err).to.not.exist
        expect(providers).to.deep.equal Object.keys PROVIDERS
        done()


  describe '#ping()', ->

    it 'should be able to ping for the given provider', (done) ->
      
      client = null

      ComputeProvider.fetchProviders client, (err, providers) ->
        expect(err).to.not.exist
        expect(providers).to.deep.equal Object.keys PROVIDERS
        done()


beforeTests()

runTests()

