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
{ forEachProvider
  withConvertedUserAnd } = require  \
  '../../../../testhelper/models/computeproviders/computeproviderhelper'

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
        expect(providers).to.deep.equal Object.keys PROVIDERS
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


  describe '::fetchUsage', ->

    it 'should be able to fetch the usage', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        options = { credential, provider : 'aws' }
        ComputeProvider.fetchUsage client, options, (err, usage) ->
          expect(err).to.not.exist
          expect(usage).to.be.an 'object'
          done()


  describe '::fetchPlans', ->

    it 'should fail if user doesnt have permission', (done) ->

      expectAccessDenied ComputeProvider, 'fetchPlans', done


    it 'should be able to fetch plans', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        ComputeProvider.fetchPlans client, (err, usage) ->
          expect(err).to.not.exist
          expect(usage).to.be.an 'object'
          done()


  describe '::fetchTeamPlans', ->

    it 'should fail if user doesnt have a valid session', (done) ->

      expectAccessDenied ComputeProvider, 'fetchTeamPlans', done


    it 'should be able to fetch team plans for koding admins', (done) ->

      withConvertedUser { role: 'admin' }, ({ client }) ->

        ComputeProvider.fetchTeamPlans client, (err, plans) ->
          expect(err).to.not.exist
          expect(plans).to.be.an 'object'
          expect(plans).to.be.deep.equal teamutils.TEAMPLANS
          done()

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


afterTests = -> after removeGeneratedCredentials

beforeTests()

runTests()

afterTests()
