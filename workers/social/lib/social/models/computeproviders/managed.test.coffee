{ _
  daisy
  expect
  withConvertedUser
  generateRandomString
  checkBongoConnectivity } = require '../../../../testhelper'
{ withConvertedUserAnd } = require \
  '../../../../testhelper/models/computeproviders/computeproviderhelper'

Managed    = require './managed'
JMachine   = require './machine'
JWorkspace = require '../workspace'

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

    it 'should fail to create managed vm if ip address is not valid', (done) ->

      withConvertedUser ({ client, account, user }) ->
        client.r = { account, user }

        options =
          label       : generateRandomString()
          ipAddress   : '127.0.0.1'
          queryString : '1/2/3/4/5/6/7/8'

        expectedQueryString = "///////#{options.queryString.split('/').reverse()[0]}"
        Managed.create client, options, (err, managedVm) ->
          expect(err?.message).to.not.exist
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

          ->
            client.r = { account, user }
            Managed.postCreate client, options, (err, data) ->
              expect(err).to.not.exist
              workspace = data
              queue.next()

          ->
            # expecting machine to be updated
            JMachine.one { _id : machine._id }, (err, machine) ->
              expect(err).to.not.exist
              expect(machine.status.state).to.be.equal 'Running'
              expect(machine.domain).to.be.equal options.postCreateOptions.ipAddress
              expect(machine.ipAddress).to.be.equal options.postCreateOptions.ipAddress
              expect(machine.queryString).to.be.equal options.postCreateOptions.queryString
              queue.next()

          ->
            # expecting workspace to be crated
            JWorkspace.one { _id : workspace._id }, (err, workspace_) ->
              expect(err).to.not.exist
              expect(workspace_).to.exist
              expect(workspace_.isDefault).to.be.truthy
              expect(workspace_.machineUId).to.be.equal machine.uid
              expect(workspace_.originId.toString()).to.be.equal account._id.toString()
              queue.next()

          -> done()

        ]

        daisy queue


  describe '#remove()', ->

    it 'should be able to remove machine with valid request', (done) ->

      options = { provider : 'managed' }
      withConvertedUserAnd ['Machine'], options, (data) ->
        { client, account, user, machine, group } = data
        client.r = { account, user, group }

        queue = [

          ->
            Managed.remove client, { machineId : machine._id.toString() }, (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            # expecting machine to be destroyed
            JMachine.one { _id : machine._id }, (err, machine) ->
              expect(err).to.not.exist
              expect(machine).to.not.exist
              queue.next()

          -> done()

        ]

        daisy queue


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

          ->
            Managed.update client, updateOptions, (err) ->
              expect(err?.message).to.not.exist
              queue.next()

          ->
            # expecting machine to be updated successfully
            JMachine.one { _id : machine._id }, (err, machine_) ->
              expect(err).to.not.exist
              expect(machine_.meta?.storage).to.be.equal updateOptions.storage
              expect(machine_.ipAddress).to.be.equal updateOptions.ipAddress
              expect(machine_.queryString).to.be.equal expectedQueryString
              queue.next()

          -> done()

        ]

        daisy queue


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

          ->
            options = generateDefaultOptions { storage : 'invalidStorage' }
            Managed.update client, options, (err) ->
              expect(err?.message).to.be.equal 'Provided storage is not valid'
              queue.next()

          ->
            options = generateDefaultOptions { ipAddress : 'invalidIP' }
            Managed.update client, options, (err) ->
              expect(err?.message).to.be.equal 'Provided IP is not valid'
              queue.next()

          ->
            options = generateDefaultOptions { queryString : '/1/2/3' }
            Managed.update client, options, (err) ->
              expect(err?.message).to.be.equal 'Provided queryString is not valid'
              queue.next()

          -> done()

        ]

        daisy queue


beforeTests()

runTests()
