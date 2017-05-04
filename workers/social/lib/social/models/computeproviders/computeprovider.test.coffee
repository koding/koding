{ async
  expect
  ObjectId
  withDummyClient
  withConvertedUser
  expectAccessDenied
  generateRandomString
  checkBongoConnectivity
  generateDummyUserFormData } = require '../../../../testhelper'
{ removeGeneratedCredentials
  withConvertedUserAndCredential } = require \
  '../../../../testhelper/models/computeproviders/credentialhelper'
{ createStackTemplate } = require \
  '../../../../testhelper/models/computeproviders/stacktemplatehelper'
{ forEachProvider
  withConvertedUserAnd } = require  \
  '../../../../testhelper/models/computeproviders/computeproviderhelper'

JGroup                    = require '../group'
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

  describe '::fetchProviders', ->

    it 'should fetch providers successfully', (done) ->

      client = null

      ComputeProvider.fetchProviders client, (err, providers) ->
        expect(err).to.not.exist
        expect(providers).to.deep.equal [
          'aws'
          'softlayer'
          'digitalocean'
          'azure'
          'google'
          'vagrant'
          'marathon'
        ]
        done()


  describe '::ping', ->

    it 'should be able to ping for the given provider', (done) ->

      withConvertedUser ({ client, account }) ->
        client.r  = { account }
        queue     = []

        forEachProvider (providerSlug, provider, callback) ->
          options = { provider }

          ComputeProvider.ping client, options, (err, data) ->
            expect(err).to.not.exist
            expect(data).to.be.a 'string'
            callback()
        , done


  describe '::ping$', ->

    it 'should not be able to ping if user doesnt have the right to ping', (done) ->

      expectAccessDenied ComputeProvider, 'ping$', { provider : PROVIDERS.aws }, done


  describe '::create', ->

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


  describe '::create$', ->

    it 'should fail if user doesnt have permission', (done) ->

      expectAccessDenied ComputeProvider, 'create$', {}, done


  describe '::fetchAvailable', ->

    it 'should be able to fetch availabe object', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        forEachProvider (providerSlug, provider, callback) ->

          options =
            provider   : providerSlug
            credential : credential

          ComputeProvider.fetchAvailable client, options, (err, data) ->
            if err
              expect(err.message).to.be.equal notImplementedMessage
              return callback()
            expect(err).to.not.exist
            expect(data).to.be.an 'array'
            callback()
        , done


    it 'should fail if no provider is given', (done) ->

      withDummyClient ({ client }) ->
        forEachProvider (providerSlug, provider, callback) ->
          ComputeProvider.fetchAvailable client, { provider : null }, (err, data) ->
            expect(err?.message).to.be.equal 'No such provider.'
            callback()
        , done


    it 'should fail if credential is not provided', (done) ->

      withDummyClient ({ client }) ->
        forEachProvider (providerSlug, provider, callback) ->
          options = { provider : providerSlug }

          ComputeProvider.fetchAvailable client, options, (err, data) ->
            expect(err?.message).to.satisfy (msg) ->
              return msg in [notImplementedMessage, 'Credential is required.']
            callback()
        , done


    it 'should fail if given credential is not valid', (done) ->

      withDummyClient ({ client }) ->
        forEachProvider (providerSlug, provider, callback) ->

          options =
            provider   : providerSlug
            credential : 'invalid'

          ComputeProvider.fetchAvailable client, options, (err, data) ->
            expect(err?.message).to.satisfy (msg) ->
              return msg in [notImplementedMessage, 'Credential failed.']
            callback()
        , done


  describe '::updateGroupStackUsage', ->

    testGroup = null

    before (done) ->
      withConvertedUser { createGroup: yes }, ({ group }) ->
        testGroup = group
        done()

    it 'should increase given group stack count', (done) ->

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

        testGroup._activeLimit = 'test'

        # checking in parallel to test lock mechanism ~ GG
        #
        async.parallel [

          (fin) ->
            ComputeProvider.updateGroupStackUsage testGroup, 'increment', fin

          (fin) ->
            ComputeProvider.updateGroupStackUsage testGroup, 'increment', fin

        ], (err) ->
          expect(err?.message).to.be.equal 'Provided limit has been reached'
          done()

    it 'should increase given group stack count taking in account plan overrides', (done) ->

      withConvertedUser { role: 'admin' }, ({ client }) ->

        overrides = { member: 3 }

        testGroup._activeLimit = 'test'

        testGroup.setLimit client, { overrides }, (err) ->
          expect(err).to.not.exist

          async.parallel [

            # keep in mind that current counter is 1 due to previous test

            (fin) ->
              ComputeProvider.updateGroupStackUsage testGroup, 'increment', fin

            (fin) ->
              ComputeProvider.updateGroupStackUsage testGroup, 'increment', fin

          ], (err) ->
            expect(err).to.not.exist

            JCounter.count
              namespace : testGroup.slug
              type      : ComputeProvider.COUNTER_TYPE.stacks
            , (err, count) ->
              expect(err).to.not.exist
              expect(count).to.be.equal overrides.member

              done()


  describe '::updateGroupInstanceUsage', ->

    testGroup = null

    before (done) ->
      withConvertedUser { createGroup: yes }, ({ group }) ->
        testGroup = group
        done()

    it 'should increase given group instance count', (done) ->

      options  =
        group  : testGroup
        change : 'increment'
        amount : 2

      ComputeProvider.updateGroupInstanceUsage options, (err) ->

        expect(err).to.not.exist

        JCounter.count
          namespace : testGroup.slug
          type      : ComputeProvider.COUNTER_TYPE.instances
        , (err, count) ->
          expect(err).to.not.exist
          expect(count).to.be.equal 2

          done()

    it 'should decrease given group instance count', (done) ->

      options  =
        group  : testGroup
        change : 'decrement'
        amount : 1

      ComputeProvider.updateGroupInstanceUsage options, (err) ->
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

        testGroup._activeLimit = 'test'

        options  =
          group  : testGroup
          change : 'increment'
          amount : 1

        ComputeProvider.updateGroupInstanceUsage options, (err) ->
          expect(err).to.exist
          expect(err.message).to.be.equal 'Provided limit has been reached'

          done()

    it 'should increase instance count taking in account plan overrides', (done) ->

      withConvertedUser { role: 'admin' }, ({ client }) ->

        testGroup._activeLimit = 'test'
        overrides = { maxInstance: 3 }

        testGroup.setLimit client, { overrides }, (err) ->
          expect(err).to.not.exist

          options  =
            group  : testGroup
            change : 'increment'
            amount : 2

          ComputeProvider.updateGroupInstanceUsage options, (err) ->
            expect(err).to.not.exist

            JCounter.count
              namespace : testGroup.slug
              type      : ComputeProvider.COUNTER_TYPE.instances
            , (err, count) ->
              expect(err).to.not.exist
              expect(count).to.be.equal overrides.maxInstance

              done()

  describe '::updateGroupResourceUsage', ->

    options = null

    before (done) ->
      withConvertedUser { createGroup: yes }, ({ group }) ->
        options         =
          group         : group
          instanceCount : 3
          change        : 'increment'
        done()

    it 'should increase given group resource count', (done) ->

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

        group._activeLimit = 'test'

        options.change = 'increment'

        ComputeProvider.updateGroupResourceUsage options, (err) ->
          expect(err).to.exist
          expect(err.message).to.be.equal 'Provided limit has been reached'

          done()


  describe '::updateTeamCounters', ->

    group = null

    before (done) ->

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


    it 'should fail if team slug not provided', (done) ->
      ComputeProvider.updateTeamCounters null, (err) ->
        expect(err).to.exist
        expect(err.message).to.be.equal 'Team slug is required'
        done()


    it 'should fail if a non existent team slug provided', (done) ->
      ComputeProvider.updateTeamCounters generateRandomString(), (err) ->
        expect(err).to.exist
        expect(err.message).to.be.equal 'Team not found'
        done()


    it 'should update given teams resource count with feedback', (done) ->

      options     =
        namespace : group.slug
        type      : ComputeProvider.COUNTER_TYPE.stacks

      queue = [
        (next) ->
          JCounter.count options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 1
            next()
        (next) ->
          JCounter.reset options, (err, count) ->
            expect(err).to.not.exist
            next()
        (next) ->
          JCounter.count options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 0
            next()
        (next) ->
          ComputeProvider.updateTeamCounters group.slug, (err, feedback) ->
            expect(err).to.not.exist
            expect(feedback).to.exist
            expect(feedback.before).to.exist
            expect(feedback.current).to.exist
            expect(feedback.after).to.exist
            expect(feedback.before.stacks).to.be.equal 0
            expect(feedback.current.stacks).to.be.equal 1
            expect(feedback.after.stacks).to.be.equal 1
            next()
        (next) ->
          JCounter.count options, (err, count) ->
            expect(err).to.not.exist
            expect(count).to.equal 1
            next()
      ]

      async.series queue, done


  describe '::update', ->

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


  describe '::createGroupStack', ->

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


  describe '::setGroupStack', ->

    it 'should be able to set provided stack as default for group', (done) ->

      # creating a new group and a new StackTemplate for that group
      groupSlug = generateRandomString()
      options   = { context : { group : groupSlug } }

      withConvertedUserAnd ['Group', 'Credential'], options, (data) ->

        { group, credential, client } = data
        options = { credentials: { aws: [ credential.getAt 'identifier' ] } }

        createStackTemplate client, options, (err, { stackTemplate }) ->
          expect(err).to.not.exist

          ComputeProvider.setGroupStack$ client, {
            templateId: stackTemplate.getId(), shareCredential: yes
          }, (err) ->
            expect(err).to.not.exist

            JGroup.one { _id: group.getId() }, (err, group) ->
              expect(err).to.not.exist
              expect(group.getAt 'stackTemplates.0').to.be.deep.equal stackTemplate.getAt '_id'
              done()



afterTests = -> after removeGeneratedCredentials

beforeTests()

runTests()

afterTests()
