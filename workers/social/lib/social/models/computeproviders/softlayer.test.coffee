{ _
  async
  expect
  KONFIG
  withCreatedUser
  withConvertedUser
  generateRandomString
  checkBongoConnectivity }  = require '../../../../testhelper'
{ fetchUserPlan }           = require './computeutils'
{ fetchMachinesByUsername } = require \
  '../../../../testhelper/models/computeproviders/machinehelper'

JMachine     = require './machine'
Softlayer    = require './softlayer'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.softlayer', ->

  describe '#providerSlug', ->

    it 'should return provider slug', ->

      expect(Softlayer.providerSlug).to.be.equal 'softlayer'


  describe '#ping()', ->

    it 'should reply to ping request', (done) ->

      withConvertedUser ({ client, account }) ->
        client.r = { account }
        expectedPong = "#{Softlayer.providerSlug} is
                        the best #{account.profile.nickname}!"
        Softlayer.ping client, {}, (err, data) ->
          expect(err?.message).to.not.exist
          expect(data).to.be.equal expectedPong
          done()


  describe '#create()', ->

    # default options for create test suite
    generateDefaultOptions = (options) ->

      return _.extend
        label        : generateRandomString()
      , options


    it 'should be able to succeed with valid request', (done) ->

      withCreatedUser ({ client, user, account, group }) ->
        client.r = { user, account, group }

        options = generateDefaultOptions()
        Softlayer.create client, options, (err, data) ->
          expect(err).to.not.exist
          expect(data.meta).to.be.an 'object'
          expect(data.meta.type).to.be.equal 'softlayer'
          expect(data.meta.storage_size).to.be.equal 10
          expect(data.meta.assignedLabel).to.be.equal options.label
          done()


beforeTests()

runTests()
