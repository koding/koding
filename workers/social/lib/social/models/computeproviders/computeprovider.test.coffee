{ daisy
  expect
  ObjectId
  withDummyClient
  withConvertedUser
  expectAccessDenied
  generateRandomString
  checkBongoConnectivity
  generateDummyUserFormData } = require '../../../../testhelper'
{ withConvertedUserAndCredential } = require \
  '../../../../testhelper/models/computeproviders/credentialhelper'
{ forEachProvider
  withConvertedUserAnd } = require  \
  '../../../../testhelper/models/computeproviders/computeproviderhelper'

async                     = require 'async'
JCounter                  = require '../counter'
JMachine                  = require './machine'
teamutils                 = require './teamutils'
ComputeProvider           = require './computeprovider'
{ PROVIDERS, revive }     = require './computeutils'
{ notImplementedMessage } = require './providerinterface'


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

      withConvertedUser ({ client, account }) ->
        client.r  = { account }
        queue     = []

        forEachProvider (providerSlug, provider) ->
          options = { provider }

          ComputeProvider.ping client, options, (err, data) ->
            expect(err).to.not.exist
            expect(data).to.be.a 'string'
        , done


  describe '#ping$()', ->

    it 'should not be able to ping if user doesnt have the right to ping', (done) ->

      expectAccessDenied ComputeProvider, 'ping$', { provider : PROVIDERS.aws }, done


  describe '#create()', ->

    it 'should be able to create a new compute provider', (done) ->

      withConvertedUserAnd ['Provisioner', 'Stack'], (data) ->
        { client, user, account, provisioner, stack, group } = data

        client.r      = { group : group.slug, user, account }
        label         = generateRandomString()
        generatedFrom = new ObjectId
        provider      = 'aws'

        options = {
          client, stack, provider, label, generatedFrom
          users : []
          provisioners : [provisioner.slug]
        }

        ComputeProvider.create client, options, (err, machine) ->
          expect(err?.message).to.not.exist
          expect(machine).to.be.an 'object'
          expect(machine.provider).to.be.equal 'aws'
          expect(machine.generatedFrom).to.be.equal generatedFrom
          expect(machine.provisioners).to.have.length 1
          expect(machine.provisioners[0]).to.be.equal provisioner.slug
          expect(machine.groups).to.have.length 1
          expect(machine.groups[0].id).to.be.deep.equal group._id
          expect(machine.domain).to.exist
          expect(machine.slug).to.exist
          expect(machine.status).to.be.an 'object'
          expect(machine.assignee).to.be.an 'object'
          done()


  describe '#create$()', ->

    it 'should fail if user doesnt have permission', (done) ->

      expectAccessDenied ComputeProvider, 'create$', {}, done


  describe '#fetchAvailable()', ->

    it 'should be able to fetch availabe object', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        forEachProvider (providerSlug) ->

          options =
            provider   : providerSlug
            credential : credential

          ComputeProvider.fetchAvailable client, options, (err, data) ->
            return expect(err.message).to.be.equal notImplementedMessage  if err
            expect(err).to.not.exist
            expect(data).to.be.an 'array'
        , done


    it 'should fail if no provider is given', (done) ->

      withDummyClient ({ client }) ->
        forEachProvider (providerSlug) ->
          ComputeProvider.fetchAvailable client, { provider : null }, (err, data) ->
            expect(err?.message).to.be.equal 'No such provider.'
        , done


    it 'should fail if credential is not provided', (done) ->

      withDummyClient ({ client }) ->
        forEachProvider (providerSlug) ->
          options = { provider : providerSlug }

          ComputeProvider.fetchAvailable client, options, (err, data) ->
            expect(err?.message).to.satisfy (msg) ->
              return msg in [notImplementedMessage, 'Credential is required.']
        , done


    it 'should fail if given credential is not valid', (done) ->

      withDummyClient ({ client }) ->
        forEachProvider (providerSlug) ->

          options =
            provider   : providerSlug
            credential : 'invalid'

          ComputeProvider.fetchAvailable client, options, (err, data) ->
            expect(err?.message).to.satisfy (msg) ->
              return msg in [notImplementedMessage, 'Credential failed.']
        , done


  describe '#fetchUsage', ->

    it 'should be able to fetch the usage', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        options = { credential, provider : 'aws' }
        ComputeProvider.fetchUsage client, options, (err, usage) ->
          expect(err).to.not.exist
          expect(usage).to.be.an 'object'
          done()


  describe '#fetchPlans', ->

    it 'should fail if user doesnt have permission', (done) ->

      expectAccessDenied ComputeProvider, 'fetchPlans', done


    it 'should be able to fetch plans', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        ComputeProvider.fetchPlans client, (err, usage) ->
          expect(err).to.not.exist
          expect(usage).to.be.an 'object'
          done()


  describe '#fetchTeamPlans', ->

    it 'should fail if user doesnt have a valid session', (done) ->

      expectAccessDenied ComputeProvider, 'fetchTeamPlans', done

    it 'should fail if user doesnt have permission', (done) ->

      withConvertedUser ({ client }) ->

        ComputeProvider.fetchTeamPlans client, (err, plans) ->
          expect(err).to.exist
          expect(err.message).to.be.equal 'Access denied'
          done()

    it 'should be able to fetch team plans for koding admins', (done) ->

      withConvertedUser { role: 'admin' }, ({ client }) ->

        ComputeProvider.fetchTeamPlans client, (err, plans) ->
          expect(err).to.not.exist
          expect(plans).to.be.an 'object'
          expect(plans).to.be.deep.equal teamutils.TEAMPLANS
          done()


  describe '#updateGroupStackUsage', ->

    testGroup = null

    it 'should increase given group stack count', (done) ->

      withConvertedUser { createGroup: yes }, ({ group }) ->

        testGroup = group

        ComputeProvider.updateGroupStackUsage testGroup, 'increment', (err) ->
          expect(err).to.not.exist

          JCounter.count
            namespace : testGroup.slug
            type      : ComputeProvider.COUNTER_TYPE.stacks
          , (err, count) ->
            expect(err).to.not.exist
            expect(count).to.be.equal 1

            done()

    it 'should decrease given group stack count', (done) ->

      ComputeProvider.updateGroupStackUsage testGroup, 'decrement', (err) ->
        expect(err).to.not.exist

        JCounter.count
          namespace : testGroup.slug
          type      : ComputeProvider.COUNTER_TYPE.stacks
        , (err, count) ->
          expect(err).to.not.exist
          expect(count).to.be.equal 0

          done()

    it 'should fail to increase stack count if plan limit has been reached', (done) ->

      withConvertedUser { role: 'admin' }, ({ client }) ->

        testGroup.setPlan client, plan: 'default', (err) ->
          expect(err).to.not.exist

          # checking in parallel to test lock mechanism ~ GG

          async.parallel [

            (fin) ->
              ComputeProvider.updateGroupStackUsage testGroup, 'increment', (err) ->
                expect(err).to.not.exist
                fin()

            (fin) ->
              ComputeProvider.updateGroupStackUsage testGroup, 'increment', (err) ->
                expect(err).to.exist
                expect(err.message).to.be.equal 'Provided limit has been reached'
                fin()

          ], done


  describe '#updateGroupInstanceUsage', ->

    testGroup = null

    it 'should increase given group instance count', (done) ->

      withConvertedUser { createGroup: yes }, ({ group }) ->

        testGroup = group

        ComputeProvider.updateGroupInstanceUsage testGroup, 'increment', 2, (err) ->

          expect(err).to.not.exist

          JCounter.count
            namespace : testGroup.slug
            type      : ComputeProvider.COUNTER_TYPE.instances
          , (err, count) ->
            expect(err).to.not.exist
            expect(count).to.be.equal 2

            done()

    it 'should decrease given group instance count', (done) ->

      ComputeProvider.updateGroupInstanceUsage testGroup, 'decrement', 1, (err) ->
        expect(err).to.not.exist

        JCounter.count
          namespace : testGroup.slug
          type      : ComputeProvider.COUNTER_TYPE.instances
        , (err, count) ->
          expect(err).to.not.exist
          expect(count).to.be.equal 1

          done()

    it 'should fail to increase instance count if plan limit has been reached', (done) ->

      withConvertedUser { role: 'admin' }, ({ client }) ->

        testGroup.setPlan client, plan: 'default', (err) ->
          expect(err).to.not.exist

          ComputeProvider.updateGroupInstanceUsage testGroup, 'increment', 1, (err) ->
            expect(err).to.exist
            expect(err.message).to.be.equal 'Provided limit has been reached'

            done()


  describe '#updateGroupResourceUsage', ->

    options = null

    it 'should increase given group resource count', (done) ->

      withConvertedUser { createGroup: yes }, ({ group }) ->

        options         =
          group         : group
          instanceCount : 3
          change        : 'increment'

        ComputeProvider.updateGroupResourceUsage options, (err) ->

          expect(err).to.not.exist

          JCounter.count
            namespace : options.group.slug
            type      : ComputeProvider.COUNTER_TYPE.instances
          , (err, count) ->
            expect(err).to.not.exist
            expect(count).to.be.equal 3

            JCounter.count
              namespace : options.group.slug
              type      : ComputeProvider.COUNTER_TYPE.stacks
            , (err, count) ->
              expect(err).to.not.exist
              expect(count).to.be.equal 1

              done()

    it 'should decrease given group resource count', (done) ->

      options.change = 'decrement'

      ComputeProvider.updateGroupResourceUsage options, (err) ->
        expect(err).to.not.exist

        JCounter.count
          namespace : options.group.slug
          type      : ComputeProvider.COUNTER_TYPE.instances
        , (err, count) ->
          expect(err).to.not.exist
          expect(count).to.be.equal 0

          JCounter.count
            namespace : options.group.slug
            type      : ComputeProvider.COUNTER_TYPE.stacks
          , (err, count) ->
            expect(err).to.not.exist
            expect(count).to.be.equal 0

            done()

    it 'should fail to increase resource count if plan limit has been reached', (done) ->

      withConvertedUser { role: 'admin' }, ({ client }) ->

        { group } = options

        group.setPlan client, plan: 'default', (err) ->
          expect(err).to.not.exist

          options.change = 'increment'

          ComputeProvider.updateGroupResourceUsage options, (err) ->
            expect(err).to.exist
            expect(err.message).to.be.equal 'Provided limit has been reached'

            done()


  describe '#update()', ->

    it 'should if no machine id is given', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->

        options =
          provider : 'aws'
          credential : credential

        ComputeProvider.update client, options, (err) ->
          expect(err?.message).to.be.equal 'A valid machineId and an update option required.'
          done()


    it 'should be able to update compute provider data', (done) ->

      withConvertedUserAnd ['Credential', 'ComputeProvider'], (data) ->
        { client, credential, machine } = data

        options =
          provider   : 'aws'
          credential : credential
          machineId  : machine._id + ''
          alwaysOn   : true

        ComputeProvider.update client, options, (err) ->
          expect(err?.message).to.not.exist
          done()


  describe '#remove()', ->

    it 'should fail if not implemented yet', (done) ->

      forEachProvider (providerSlug) ->

        options = { provider : providerSlug }
        withConvertedUserAnd ['ComputeProvider'], options, (data) ->
          { client, machine } = data

          queue = [

            ->
              JMachine.one { _id : machine._id }, (err, machine) ->
                expect(err).to.not.exist
                expect(machine).to.exist
                queue.next()

            ->
              options = { provider : providerSlug, machineId : machine._id.toString() }
              ComputeProvider.remove client, options, (err) ->
                if err
                  return expect(err.message).to.be.equal notImplementedMessage
                queue.next()

            ->
              JMachine.one { _id : machine._id }, (err, machine) ->
                expect(err).to.not.exist
                expect(machine).to.not.exist
                queue.next()

          ]

          daisy queue
      , done


  describe 'createGroupStack', ->

    it 'should be able to create group stack', (done) ->

      # creating a new group and a new StackTemplate for that group
      groupSlug = generateRandomString()
      options   = { context : { group : groupSlug } }

      withConvertedUserAnd ['Group', 'StackTemplate'], options, (data) ->
        { group, client } = data

        ComputeProvider.createGroupStack data.client, (err, groupStack) ->
          expect(err?.message).to.not.exist
          expect(groupStack).to.exist
          expect(groupStack).to.be.an 'object'
          expect(groupStack.originId).to.be.deep.equal client._id
          done()



beforeTests()

runTests()
