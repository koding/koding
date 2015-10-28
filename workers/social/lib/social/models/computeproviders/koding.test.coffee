{ daisy
  expect
  KONFIG
  fetchGroup
  withConvertedUser
  checkBongoConnectivity }  = require '../../../../testhelper'
{ fetchUserPlan }           = require './computeutils'
{ fetchMachinesByUsername } = require \
  '../../../../testhelper/models/computeproviders/machinehelper'

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

    it 'should be able to succeed with valid request', (done) ->

      withConvertedUser ({ userFormData }) ->
        fetchMachinesByUsername userFormData.username, (machines) ->
          machine = machines[0]
          expect(machine.label).to.exist
          expect(machine.status).to.be.an 'object'
          expect(machine.status.state).to.be.equal 'NotInitialized'
          expect(machine.provider).to.be.equal Koding.providerSlug
          expect(machine.meta).to.be.an 'object'
          expect(machine.meta.type).to.be.equal 'aws'
          expect(machine.meta).to.be.falsy
          expect(machine.meta.region).to.exist
          expect(machine.meta.source_ami).to.be.empty
          expect(machine.meta.storage_size).to.be.a 'number'
          expect(machine.generatedFrom).to.be.an 'object'
          expect(machine.generatedFrom.templateId).to.exist
          expect(machine.users).to.be.an.instanceof Array
          expect(machine.users[0].username).to.be.equal userFormData.username
          expect(machine.credential).to.be.equal userFormData.username
          expect(machine.provisioners).to.be.an.instanceof Array
          expect(machine.groups).to.be.an.instanceof Array
          expect(machine.uid).to.exist
          expect(machine.createdAt).to.be.an.instanceof Date
          expect(machine.assignee).to.be.an 'object'
          expect(machine.domain).to.be.a 'string'
          expect(machine.slug).to.be.a 'string'
          done()


  describe '#postCreate()', ->

    it 'should create domain alias and workspace', (done) ->

      withConvertedUser ({ userFormData, client, account }) ->

        client.r  = { account }
        machine   = {}

        queue = [

          ->
            fetchMachinesByUsername userFormData.username, (machines) ->
              machine = machines[0]
              queue.next()

          ->
            Koding.postCreate client, { machine }, (err, workspace_) ->
              expect(err).to.not.exist
              expect(workspace_.isDefault).to.be.truthy
              expect(workspace_.machineUId).to.be.equal machine.uid
              expect(workspace_.originId).to.be.deep.equal account._id
              queue.next()

          ->
            options   = { machineId : machine._id.toString() }
            topDomain = "#{account.profile.nickname}.#{KONFIG.userSitesDomain}"
            JDomainAlias.one options, (err, domainAlias) ->
              expect(domainAlias.domain).to.be.equal topDomain
              expect(domainAlias.originId).to.be.deep.equal account._id
              queue.next()

          -> done()

        ]

        daisy queue



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

          ->
            fetchUserPlan client, (err, userPlan_) ->
              expect(err).to.not.exist
              userPlan = userPlan_
              queue.next()

          ->
            expectedError = "Requested new size exceeds
                              allowed\nlimit of #{userPlan.storage}GB."
            options = { alwaysOn : false, resize : userPlan.storage + 1 }
            Koding.update client, options, (err) ->
              expect(err?.message).to.be.equal expectedError
              queue.next()

          -> done()

        ]

        daisy queue


    it 'should be able to succeed with valid request', (done) ->

      withConvertedUser ({ client, account, user, userFormData }) ->

        machine = {}

        queue = [

          ->
            fetchMachinesByUsername userFormData.username, (machines) ->
              machine = machines[0]
              queue.next()

          ->
            fetchGroup client, (group) ->
              client.r = { account, user, group }
              queue.next()

          ->
            options =
              alwaysOn  : false
              machineId : machine._id.toString()

            Koding.update client, options, (err) ->
              expect(err?.message).to.not.exist
              queue.next()

          ->
            JMachine.one { _id : machine._id }, (err, machine_) ->
              expect(err?.message).to.not.exist
              expect(machine_.alwaysOn).to.be.falsy
              queue.next()

          -> done()

        ]

        daisy queue


  describe '#fetchAvailable()', ->

    it 'should be able fech data', (done) ->

      Koding.fetchAvailable null, {}, (err, data) ->
        expect(err).to.not.exist
        expect(data).to.be.an 'array'
        done()


beforeTests()

runTests()
