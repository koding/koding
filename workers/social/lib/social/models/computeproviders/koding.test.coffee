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

Koding       = require './koding'
JMachine     = require './machine'
JDomainAlias = require '../domainalias'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.koding', ->

  describe '#providerSlug', ->

    it 'should return provider slug', ->

      expect(Koding.providerSlug).to.be.equal 'koding'


  describe '#ping()', ->

    it 'should reply to ping request', (done) ->

      withConvertedUser ({ client, account }) ->
        client.r = { account }
        expectedPong = "#{Koding.providerSlug} is
                        the best #{account.profile.nickname}!"
        Koding.ping client, {}, (err, data) ->
          expect(err?.message).to.not.exist
          expect(data).to.be.equal expectedPong
          done()


  describe '#create()', ->

    # default options for create test suite
    generateDefaultOptions = (options) ->

      return _.extend
        label        : generateRandomString()
        region       : 'us-east-1'
        storage      : '3'
        instanceType : 't2.nano'
      , options


    it 'should be able to succeed with valid request', (done) ->

      withCreatedUser ({ client, user, account, group }) ->
        client.r = { user, account, group }

        queue = [

          (next) ->
            options = generateDefaultOptions()
            Koding.create client, options, (err, data) ->
              expect(err).to.not.exist
              expect(data.meta).to.be.an 'object'
              expect(data.meta.type).to.be.equal 'aws'
              expect(data.meta.region).to.be.equal options.region
              expect(data.meta.source_ami).to.be.empty
              expect(data.meta.storage_size.toString()).to.be.equal options.storage
              expect(data.meta.alwaysOn).to.be.false
              expect(data.label).to.be.a 'string'
              expect(data.credential).to.be.equal user.username
              next()

        ]

        async.series queue, done


    it 'should be able to succeed when snapshotId provided', (done) ->

      withConvertedUser ({ client, user, account, group }) ->

        client.r = { user, account, group }
        snapshot = {}

        queue = [

          (next) ->
            createSnapshot { originId : account.getId() }, (err, snapshot_) ->
              expect(err).to.not.exist
              snapshot = snapshot_
              next()

          (next) ->
            # removing existing machine to be able to create a new Koding machine
            fetchMachinesByUsername user.username, (machines) ->
              machine = machines[0]

              JMachine.remove { _id : machine._id }, (err) ->
                expect(err).to.not.exist
                next()

          (next) ->
            options = generateDefaultOptions { snapshotId : snapshot.snapshotId }
            Koding.create client, options, (err, data) ->
              expect(err).to.not.exist
              expect(data.meta).to.be.an 'object'
              expect(data.meta.type).to.be.equal 'aws'
              expect(data.meta.region).to.be.equal options.region
              expect(data.meta.source_ami).to.be.empty
              expect(data.meta.storage_size.toString()).to.be.equal options.storage
              expect(data.meta.alwaysOn).to.be.false
              expect(data.meta.snapshotId).to.be.equal options.snapshotId
              expect(data.label).to.be.a 'string'
              expect(data.credential).to.be.equal user.username
              next()

        ]

        async.series queue, done


    it 'should fail if storage is not valid', (done) ->

      withCreatedUser ({ client, user, account }) ->
        client.r = { user, account }

        queue         = []
        storageValues = ['notValidStorage', '2', '101']

        storageValues.forEach (storageValue) ->
          queue.push (next) ->
            options = generateDefaultOptions { storage : storageValue }
            Koding.create client, options, (err) ->
              expect(err?.message).to.be.equal 'Requested storage size is not valid.'
              next()

        async.series queue, done


    it 'should fail if storage exceeds allowed size', (done) ->

      withCreatedUser ({ client, user, account, group }) ->

        client.r = { user, account, group }
        userPlan = {}

        queue = [

          (next) ->
            fetchUserPlan client, (err, userPlan_) ->
              expect(err).to.not.exist
              userPlan = userPlan_
              next()

          (next) ->
            expectedError = "Total limit of #{userPlan.storage}GB storage
                              limit has been reached."
            options = generateDefaultOptions { storage : '10' }
            Koding.create client, options, (err) ->
              expect(err?.message).to.be.equal expectedError
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
            Koding.postCreate client, { machine }, (err, workspace_) ->
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
        Koding.update client, {}, (err) ->
          expect(err?.message).to.be.equal expectedError
          done()


    it 'should fail if resize exceeds plan limit', (done) ->

      withConvertedUser ({ client, account, user, userFormData }) ->

        userPlan = null
        client.r = { account, user }

        queue = [

          (next) ->
            fetchUserPlan client, (err, userPlan_) ->
              expect(err).to.not.exist
              userPlan = userPlan_
              next()

          (next) ->
            expectedError = "Requested new size exceeds
                              allowed\nlimit of #{userPlan.storage}GB."
            options = { alwaysOn : false, resize : userPlan.storage + 1 }
            Koding.update client, options, (err) ->
              expect(err?.message).to.be.equal expectedError
              next()

        ]

        async.series queue, done


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

            Koding.update client, options, (err) ->
              expect(err?.message).to.not.exist
              next()

          (next) ->
            JMachine.one { _id : machine._id }, (err, machine_) ->
              expect(err?.message).to.not.exist
              expect(machine_.alwaysOn).to.be.falsy
              next()

        ]

        async.series queue, done


  describe '#fetchAvailable()', ->

    it 'should be able fech data', (done) ->

      Koding.fetchAvailable null, {}, (err, data) ->
        expect(err).to.not.exist
        expect(data).to.be.an 'array'
        done()


beforeTests()

runTests()
