{ _
  async
  expect
  withConvertedUser
  generateRandomString
  checkBongoConnectivity } = require '../../../../testhelper'
{ withConvertedUserAnd } = require \
  '../../../../testhelper/models/computeproviders/computeproviderhelper'

async           = require 'async'
Managed         = require './managed'
JMachine        = require './machine'
ComputeProvider = require './computeprovider'

# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.managed', ->

  describe '#ping()', ->

    it 'should be able to ping', (done) ->

      withConvertedUser ({ client, account }) ->
        client.r = { account }

        expectedPong = "#{Managed.providerSlug} VMs rulez #{account.profile.nickname}!"
        Managed.ping client, {}, (err, data) ->
          expect(err?.message).to.not.exist
          expect(data).to.be.equal expectedPong
          done()


  describe '#create()', ->

    options             =
      label             : generateRandomString()
      ipAddress         : '127.0.0.1'
      queryString       : '1/2/3/4/5/6/7/8'

    expectedQueryString = "///////#{options.queryString.split('/').reverse()[0]}"

    it 'should be able to create required managed vm data', (done) ->

      withConvertedUser ({ client, account, user, group }) ->
        client.r = { account, user, group }

        Managed.create client, options, (err, managedVm) ->
          expect(err).to.not.exist
          expect(managedVm.label).to.be.equal options.label
          expect(managedVm.meta).to.be.an 'object'
          expect(managedVm.meta.type).to.be.equal Managed.providerSlug
          expect(managedVm.meta.storage_size).to.be.equal 0
          expect(managedVm.meta.alwaysOn).to.be.falsy
          expect(managedVm.credential).to.be.equal user.username
          expect(managedVm.postCreateOptions).to.be.an 'object'
          expect(managedVm.postCreateOptions.queryString).to.be.equal expectedQueryString
          expect(managedVm.postCreateOptions.ipAddress).to.equal options.ipAddress
          done()


    it 'should fail to create required managed vm data if group limit has been reached', (done) ->

      withConvertedUser { createGroup: 'yes' }, ({ client, account, user, group }) ->

        async.series [

          (next) ->
            withConvertedUser { role: 'admin' }, (data) ->
              _client = data.client
              group._activeLimit = 'test'
              next()

          (next) ->

            _options = {
              instanceCount : 1
              instanceOnly  : yes
              details       : { account, provider: 'managed' }
              change        : 'increment'
              group
            }

            ComputeProvider.updateGroupResourceUsage _options, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            client.r = { account, user, group }
            Managed.create client, options, (err) ->
              expect(err).to.exist
              expect(err.message).to.be.equal 'Provided limit has been reached'

              next()

        ], done


  describe '#postCreate()', ->

    it 'should update machine and create workspace', (done) ->

      options = { provider : 'managed' }
      withConvertedUserAnd ['Machine'], options, ({ client, account, user, machine }) ->

        workspace = {}

        options =
          machine           : machine
          postCreateOptions :
            ipAddress       : '127.0.0.1'
            queryString     : '///////kiteId'

        queue = [

          (next) ->
            client.r = { account, user }
            Managed.postCreate client, options, (err, data) ->
              expect(err).to.not.exist
              workspace = data
              next()

          (next) ->
            # expecting machine to be updated
            JMachine.one { _id : machine._id }, (err, machine) ->
              expect(err).to.not.exist
              expect(machine.status.state).to.be.equal 'Running'
              expect(machine.domain).to.be.equal options.postCreateOptions.ipAddress
              expect(machine.ipAddress).to.be.equal options.postCreateOptions.ipAddress
              expect(machine.queryString).to.be.equal options.postCreateOptions.queryString
              next()

        ]

        async.series queue, done


  describe '#remove()', ->

    it 'should be able to remove machine with valid request', (done) ->

      options = { provider : 'managed' }
      withConvertedUserAnd ['Machine'], options, (data) ->
        { client, account, user, machine, group } = data
        client.r = { account, user, group }

        queue = [

          (next) ->
            Managed.remove client, { machineId : machine._id.toString() }, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            # expecting machine to be destroyed
            JMachine.one { _id : machine._id }, (err, machine) ->
              expect(err).to.not.exist
              expect(machine).to.not.exist
              next()

        ]

        async.series queue, done


  describe '#update()', ->

    it 'should be able to update machine with valid request', (done) ->

      options = { provider : 'managed' }
      withConvertedUserAnd ['Machine'], options, (data) ->
        { client, account, user, machine, group } = data
        client.r = { account, user, group }

        updateOptions =
          storage     : '1'
          machineId   : machine._id.toString()
          ipAddress   : '0.0.0.0'
          queryString : '1/2/3/4/5/6/7/8'

        expectedQueryString = "///////#{updateOptions.queryString.split('/').reverse()[0]}"

        queue = [

          (next) ->
            Managed.update client, updateOptions, (err) ->
              expect(err?.message).to.not.exist
              next()

          (next) ->
            # expecting machine to be updated successfully
            JMachine.one { _id : machine._id }, (err, machine_) ->
              expect(err).to.not.exist
              expect(machine_.meta?.storage).to.be.equal updateOptions.storage
              expect(machine_.ipAddress).to.be.equal updateOptions.ipAddress
              expect(machine_.queryString).to.be.equal expectedQueryString
              next()

        ]

        async.series queue, done


    it 'should fail when required options not provided', (done) ->

      withConvertedUser ({ client, account, user, group }) ->
        client.r      = { account, user, group }
        expectedError = 'A valid machineId and an update option is required.'

        Managed.update client, {}, (err) ->
          expect(err?.message).to.be.equal expectedError
          done()


    it 'should fail if provided some options are not valid', (done) ->

      withConvertedUser ({ client, account, user, group }) ->

        generateDefaultOptions = (options) ->

          _options =
            storage     : '1'
            machineId   : generateRandomString()
            ipAddress   : '0.0.0.0'
            queryString : '1/2/3/4/5/6/7/8'

          _options = _.extend _options, options

          return _options

        client.r = { account, user, group }

        queue = [

          (next) ->
            options = generateDefaultOptions { storage : 'invalidStorage' }
            Managed.update client, options, (err) ->
              expect(err?.message).to.be.equal 'Provided storage is not valid'
              next()

          (next) ->
            options = generateDefaultOptions { queryString : '/1/2/3' }
            Managed.update client, options, (err) ->
              expect(err?.message).to.be.equal 'Provided queryString is not valid'
              next()

        ]

        async.series queue, done


beforeTests()

runTests()
