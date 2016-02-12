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
{ createSnapshot }          = require \
  '../../../../testhelper/models/computeproviders/snapshothelper'

JMachine     = require './machine'
Softlayer    = require './softlayer'
JDomainAlias = require '../domainalias'


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

        queue = [

          (next) ->
            options = generateDefaultOptions()
            Softlayer.create client, options, (err, data) ->
              expect(err).to.not.exist
              expect(data.meta).to.be.an 'object'
              expect(data.meta.type).to.be.equal 'softlayer'
              expect(data.meta.storage_size).to.be.equal 25
              expect(data.meta.alwaysOn).to.be.false
              expect(data.label).to.be.a 'string'
              expect(data.credential).to.be.equal user.username
              next()

        ]

        async.series queue, done


  describe '#postCreate()', ->

    it 'should create domain alias and workspace', (done) ->

      withConvertedUser ({ userFormData, client, account }) ->

        client.r  = { account }
        machine   = {}

        queue = [

          (next) ->
            fetchMachinesByUsername userFormData.username, (machines) ->
              machine = machines[0]
              next()

          (next) ->
            Softlayer.postCreate client, { machine }, (err, workspace_) ->
              expect(err).to.not.exist
              expect(workspace_.isDefault).to.be.truthy
              expect(workspace_.machineUId).to.be.equal machine.uid
              expect(workspace_.originId).to.be.deep.equal account._id
              next()

          (next) ->
            options   = { machineId : machine._id.toString() }
            topDomain = "#{account.profile.nickname}.#{KONFIG.userSitesDomain}"
            JDomainAlias.one options, (err, domainAlias) ->
              expect(domainAlias.domain).to.be.equal topDomain
              expect(domainAlias.originId).to.be.deep.equal account._id
              next()

        ]

        async.series queue, done



  describe '#update()', ->

    it 'should fail if required options is not set', (done) ->

      withConvertedUser ({ client, account, user, userFormData }) ->

        client.r      = { account, user }
        expectedError = 'A valid machineId and an update option required.'
        Softlayer.update client, {}, (err) ->
          expect(err?.message).to.be.equal expectedError
          done()


    it 'should be able to succeed with valid request', (done) ->

      withConvertedUser ({ client, account, group, user, userFormData }) ->

        machine  = {}
        client.r = { account, user, group }

        queue = [

          (next) ->
            fetchMachinesByUsername userFormData.username, (machines) ->
              machine = machines[0]
              next()

          (next) ->
            options =
              alwaysOn  : false
              machineId : machine._id.toString()

            Softlayer.update client, options, (err) ->
              expect(err?.message).to.not.exist
              next()

          (next) ->
            JMachine.one { _id : machine._id }, (err, machine_) ->
              expect(err?.message).to.not.exist
              expect(machine_.alwaysOn).to.be.falsy
              next()

        ]

        async.series queue, done


beforeTests()

runTests()
