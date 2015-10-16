
{ PLANS, PROVIDERS, fetchGroupStackTemplate, revive,
  fetchUsage, checkTemplateUsage } = require './computeutils'

{ daisy
  expect
  withDummyClient
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

      withConvertedUser {}, ({ client, account }) ->
        client.r  = { account }
        queue     = []

        for providerSlug, provider of PROVIDERS
          queue.push ->
            options = { provider }
            ComputeProvider.ping client, options, (err, data) ->
              expect(err).to.not.exist
              expect(data).to.be.a 'string'
              queue.next()

        queue.push -> done()

        daisy queue


  describe '#ping$()', ->

    it 'should not be able to ping if user doesnt have the right to ping', (done) ->

      withDummyClient { group : 'koding' }, ({ client }) ->

        ComputeProvider.ping$ client, { provider : PROVIDERS.google }, (err, data) ->
          expect(err?.message).to.be.equal 'Access denied'
          done()


  describe.skip '#create()', ->

    it 'should fail when user is not registered', (done) ->

      withDummyClient { group : 'koding' }, ({ client }) ->






beforeTests()

runTests()

