JUser                         = require '../user/index'
JMachine                      = require './machine'

{ createUserAndMachine
  generateMachineParams
  fetchMachinesByUsername }   = require '../../../../testhelper/models/computeproviders/machinehelper'

{ withConvertedUserAndProvisioner } = require '../../../../testhelper/models/computeproviders/provisionerhelper'

{ async
  expect
  withDummyClient
  generateUserInfo
  withConvertedUser
  generateRandomString
  checkBongoConnectivity
  generateRandomUserArray
  generateDummyUserFormData } = require '../../../../testhelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.machine', ->

  describe '#create()', ->

    it 'should fail when machine data is not valid', (done) ->

      machineParams = {}

      queue = [

        (next) ->
          withDummyClient { group : 'koding' }, ({ client }) ->

            # generating machineParams to use on machine creation
            generateMachineParams client, (err, data) ->
              expect(err).to.not.exist
              machineParams = data
              next()

        (next) ->
          # sending machineParams.user null and expecting error
          machineParams.user = null
          JMachine.create machineParams, (err, data) ->
            expect(err?.message).to.be.equal 'user is not set!'
            next()

      ]

      async.series queue, done


    describe 'when machine data is valid', ->

      it 'a new machine should be created for revived client', (done) ->

        machineParams = {}

        queue = [

          (next) ->
            withDummyClient { group : 'koding' }, ({ client }) ->

              # generating machineParams to use on machine creation
              generateMachineParams client, (err, data) ->
                expect(err).to.not.exist
                machineParams = data
                next()

          (next) ->
            # expecting machine to be craeted
            JMachine.create machineParams, (err, machine) ->
              expect(err).to.not.exist
              expect(machine.provider).to.be.equal machineParams.provider
              expect(machine.status.state).to.be.equal 'NotInitialized'
              expect(machine.label).to.exist
              expect(machine.users.length).to.be.above 0
              expect(machine.users[0].sudo).to.be.ok
              expect(machine.users[0].owner).to.be.ok
              expect(machine.domain).to.exist
              expect(machine.slug).to.exist
              next()

        ]

        async.series queue, done


      it 'a new machine should be created for created user', (done) ->

        # creating a user and a machine with newly created user
        createUserAndMachine generateUserInfo(), (err, data) ->
          { machine, user } = data
          expect(err).to.not.exist
          expect(machine.provider).to.be.equal 'aws'
          expect(machine.status.state).to.be.equal 'NotInitialized'
          expect(machine.users[0].id + '').to.be.equal user.getId() + ''
          expect(machine.label).to.exist
          expect(machine.users.length).to.be.above 0
          expect(machine.users[0].sudo).to.be.ok
          expect(machine.users[0].owner).to.be.ok
          expect(machine.domain).to.exist
          expect(machine.slug).to.exist

          done()


  describe '#destroy()', ->

    describe 'when user is the owner', ->

      it 'machine should be destroyed', (done) ->

        user          = {}
        machine       = {}
        userInfo      = generateUserInfo()

        queue = [

          (next) ->
            createUserAndMachine userInfo, (err, data) ->
              expect(err).to.not.exist
              { machine, user } = data
              userCount         = machine.users.length
              next()

          (next) ->
            # expecting machine to be destroyed without error
            _client = { r : { user } }
            machine.destroy _client, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            # fetching machine instances again expecting machine to be destroyed
            JMachine.fetchByUsername userInfo.username, (err, machines) ->
              expect(err).to.not.exist
              expect(machines.length).to.be.equal 0
              next()

        ]

        async.series queue, done


    describe 'when user is not the owner', ->

      it 'destroy attempt with another user should fail', (done) ->

        user          = {}
        machine       = {}
        userInfo      = generateUserInfo()
        anotherUser   = {}
        machineCount  = 0

        queue = [

          (next) ->
            createUserAndMachine userInfo, (err, data) ->
              expect(err).to.not.exist
              { machine } = data
              userCount   = machine.users.length
              next()

          (next) ->
            JUser.createUser generateUserInfo(), (err, user_, account_) ->
              expect(err).to.not.exist
              anotherUser = user_
              next()

          (next) ->
            # expecting destroy attempt with another user to fail
            _client = { r : { user : anotherUser } }
            machine.destroy _client, (err) ->
              expect(err?.message).to.be.equal 'Access denied'
              next()

        ]

        async.series queue, done


  describe '#addUsers()', ->

    describe 'when data is valid', ->

      it 'should be able to add a new user to machine', (done) ->

        machine       = {}
        userInfo      = generateUserInfo()
        userCount     = 0
        anotherUser   = {}

        queue = [

          (next) ->
            createUserAndMachine userInfo, (err, data) ->
              expect(err).to.not.exist
              { machine } = data
              userCount   = machine.users.length
              next()

          (next) ->
            JUser.createUser generateUserInfo(), (err, user_, account_) ->
              expect(err).to.not.exist
              anotherUser = user_
              next()

          (next) ->
            # expecting another user to be added
            params =
              targets   : [anotherUser]
              asOwner   : yes
              permanent : yes

            machine.addUsers params, (err) ->
              expect(err).to.not.exist
              expect(machine.users.length).to.be.equal userCount + 1
              next()

        ]

        async.series queue, done


    describe 'when data is not valid', ->

      it 'should fail if targets.length is greater than limit', (done) ->

        limit         = 50
        queue         = []
        targets       = []
        machine       = {}

        queue.push (next) ->
          createUserAndMachine generateUserInfo(), (err, data) ->
            expect(err).to.not.exist
            { machine } = data
            next()

        queue.push (next) ->
          generateRandomUserArray limit, (userArray) ->
            targets = userArray
            next()

        queue.push (next) ->
          params =
            targets   : targets
            asOwner   : yes
            permanent : yes

          expectedError = "Machine sharing is limited up to #{limit} users."
          machine.addUsers params, (err) ->
            expect(err?.message).to.be.equal expectedError
            next()

        async.series queue, done


  describe '#removeUsers()', ->

    describe 'when data is valid', ->

      it 'user should be removed from machine', (done) ->

        queue            = []
        targets          = []
        machine          = {}
        userCount        = 0
        addedUserCount   = 5
        removedUserCount = 2

        queue.push (next) ->
          createUserAndMachine generateUserInfo(), (err, data) ->
            expect(err).to.not.exist
            { machine } = data
            userCount   = machine.users.length
            next()

        queue.push (next) ->
          generateRandomUserArray addedUserCount, (userArray) ->
            targets = userArray
            next()

        # first adding users
        queue.push (next) ->
          params =
            targets   : targets
            asOwner   : yes
            permanent : yes

          machine.addUsers params, (err) ->
            expect(err).to.not.exist
            expect(machine.users.length).to.be.equal userCount + addedUserCount
            next()

        # then removing some users and expecting no error
        queue.push (next) ->
          params =
            targets   : targets.slice 0, removedUserCount
            asOwner   : yes
            permanent : yes

          expectedUserCount = userCount + addedUserCount - removedUserCount
          machine.removeUsers params, (err) ->
            expect(err).to.not.exist
            expect(machine.users.length).to.be.equal expectedUserCount
            next()

        async.series queue, done


  describe '#shareWith()', ->

    describe 'when data is not valid', ->

      it 'should fail if target is not specified', (done) ->

        machine       = {}
        userInfo      = generateUserInfo()

        queue = [

          (next) ->
            createUserAndMachine userInfo, (err, data) ->
              expect(err).to.not.exist
              { machine } = data
              next()

          (next) ->
            # expecting error when target is not specified
            params = { target : null }
            machine.shareWith params, (err, machine_) ->
              expect(err?.message).to.be.equal 'Target required.'
              next()

        ]

        async.series queue, done


      it 'should fail if target is not an instance of juser', (done) ->

        machine       = {}
        userInfo      = generateUserInfo()

        queue = [

          (next) ->
            createUserAndMachine userInfo, (err, data) ->
              expect(err).to.not.exist
              { machine } = data
              next()

          (next) ->
            # expecting error when target is invalid
            params = { target : ['invalidTarget'] }
            machine.shareWith params, (err, machine_) ->
              expect(err?.message).to.be.equal 'Target does not support machines.'
              next()

        ]

        async.series queue, done

    describe 'when data is valid', ->

      it 'should share machine if asUser is truthy', (done) ->

        machine       = {}
        userInfo      = generateUserInfo()
        userCount     = 0
        anotherUser   = {}

        queue = [

          (next) ->
            createUserAndMachine userInfo, (err, data) ->
              expect(err).to.not.exist
              { machine } = data
              userCount = machine.users.length
              next()

          (next) ->
            JUser.createUser generateUserInfo(), (err, user_) ->
              expect(err).to.not.exist
              anotherUser = user_
              next()

          (next) ->
            # expecting user to be added when asUser is yes
            params = { target : [anotherUser.username], asUser : yes }
            machine.shareWith params, (err) ->
              expect(err).to.not.exist
              expect(machine.users.length).to.be.equal userCount + 1
              next()

          (next) ->
            # expecting user to be removed when asUser is no
            params = { target : [anotherUser.username], asUser : no }
            machine.shareWith params, (err) ->
              expect(err).to.not.exist
              expect(machine.users.length).to.be.equal userCount
              next()

        ]

        async.series queue, done


  describe '#fetchOwner()', ->

    it 'should fail when there is no owner', (done) ->

      machine       = {}
      userInfo      = generateUserInfo()
      userCount     = 0

      queue = [

        (next) ->
          createUserAndMachine userInfo, (err, data) ->
            expect(err).to.not.exist
            { machine } = data
            next()

        (next) ->
          # setting machine owner to false
          machine.update { $set : { 'users.0.owner' : no } }, (err) ->
            expect(err).to.not.exist
            next()

        (next) ->
          # expecting error when there is no owner
          machine.fetchOwner (err) ->
            expect(err?.message).to.be.equal 'Owner user not found'
            next()

      ]

      async.series queue, done


    it 'should return the owner when data is valid', (done) ->

      user          = {}
      machine       = {}
      userInfo      = generateUserInfo()
      userCount     = 0

      queue = [

        (next) ->
          createUserAndMachine userInfo, (err, data) ->
            expect(err).to.not.exist
            { machine, user } = data
            next()

        (next) ->
          # expecting owner to be fetched
          machine.fetchOwner (err, owner) ->
            expect(err).to.not.exist
            expect(owner).to.exist
            expect(owner.profile.nickname).to.be.equal user.username
            next()

      ]

      async.series queue, done


  describe '#one$()', ->

    it 'should fetch machine instance', (done) ->

      user             = {}
      client           = {}
      account          = {}
      userFormData     = generateDummyUserFormData()

      queue = [

        (next) ->
          withConvertedUser { userFormData }, (data) ->
            { client } = data
            next()

        (next) ->
          # fetching machine instance of newly registered user
          fetchMachinesByUsername userFormData.username, (machines) ->
            machine = machines[0]

            # expecting machine to be fetched by machine id and client
            JMachine.one$ client, { _id: machine._id }, (err, machine_) ->
              expect(err).to.not.exist
              expect(machine).to.exist
              expect(machine._id + '').to.be.equal machine_._id + ''
              next()

      ]

      async.series queue, done


  describe '#reviveUsers()', ->

    describe 'when data is not valid', ->

      it 'should fail if user is not owner', (done) ->

        client           = {}
        account          = {}
        userFormData     = generateDummyUserFormData()
        anotherClient    = {}

        queue = [

          (next) ->
            withConvertedUser { userFormData }, (data) ->
              { client } = data
              next()

          (next) ->
            withConvertedUser {}, (data) ->
              { client : anotherClient } = data

              # fetching owner user's machine
              fetchMachinesByUsername userFormData.username, (machines) ->
                machine = machines[0]

                # expecting error when another user attempts to revive users
                machine.reviveUsers anotherClient, {}, (err) ->
                  expect(err?.message).to.be.equal 'Access denied'
                  next()

        ]

        async.series queue, done


    describe 'when data is valid', ->

      it 'should revive users', (done) ->

        client           = {}
        account          = {}
        userFormData     = generateDummyUserFormData()

        queue = [

          (next) ->
            withConvertedUser { userFormData }, (data) ->
              { client } = data
              next()

          (next) ->
            # fetching machine of owner user
            fetchMachinesByUsername userFormData.username, (machines) ->
              machine = machines[0]

              # expecting to revive users without error
              machine.reviveUsers client, {}, (err) ->
                expect(err?.message).to.not.exist
                next()

        ]

        async.series queue, done


  describe '#setLabel()', ->

    describe 'when data is not valid', ->

      it 'should fail if user is not owner or label is empty', (done) ->

        client           = {}
        machine          = {}
        account          = {}
        userFormData     = generateDummyUserFormData()
        anotherClient    = {}

        queue = [

          (next) ->
            withConvertedUser { userFormData }, (data) ->
              { client } = data
              next()

          (next) ->
            withConvertedUser {}, (data) ->
              { client : anotherClient } = data
              next()

          (next) ->
            # fetching machine of user
            JMachine.fetchByUsername userFormData.username, (err, machines) ->
              expect(err).to.not.exist
              machine = machines[0]
              next()

          (next) ->
            # expecting error when another user makes setLabel request
            machine.setLabel anotherClient, 'someLabel', (err) ->
              expect(err?.message).to.be.equal 'Access denied'
              next()

          (next) ->
            # expecting error when label is empty
            machine.setLabel client, '', (err) ->
              expect(err?.message).to.be.equal 'Nickname cannot be empty'
              next()

        ]

        async.series queue, done


    describe 'when data is valid', ->

      it 'should be able set label on machine', (done) ->

        client           = {}
        account          = {}
        userFormData     = generateDummyUserFormData()

        queue = [

          (next) ->
            withConvertedUser { userFormData }, (data) ->
              { client } = data
              next()

          (next) ->
            fetchMachinesByUsername userFormData.username, (machines) ->
              machine = machines[0]

              # generating random label and expecting machine label to be set to it
              newLabel = generateRandomString()
              machine.setLabel client, newLabel, (err) ->
                expect(err).to.not.exist
                expect(machine.label).to.be.equal newLabel
                next()

        ]

        async.series queue, done


  describe '#setProvisioner()', ->

    describe 'when data is not valid', ->

      it 'should fail when user is not owner', (done) ->

        user               = {}
        machine            = {}
        anotherUserAccount = {}

        queue = [

          (next) ->
            createUserAndMachine generateUserInfo(), (err, data) ->
              expect(err).to.not.exist
              { machine, user } = data
              next()

          (next) ->
            JUser.createUser generateUserInfo(), (err, user_, account_) ->
              expect(err).to.not.exist
              anotherUserAccount = account_
              next()

          (next) ->
            # expecting error when another user makes request
            _client =
              connection : { delegate : anotherUserAccount }
              context    : { group    : 'koding' }

            machine.setProvisioner _client, '', (err) ->
              expect(err?.message).to.be.equal 'Access denied'
              next()

        ]

        async.series queue, done


    describe 'when data is valid', ->

      it 'should set provisioner when user is the owner', (done) ->

        user             = {}
        client           = {}
        account          = {}
        provisioner      = null
        userFormData     = generateDummyUserFormData()
        provisionerCount = 0

        queue = [

          (next) ->
            withConvertedUserAndProvisioner { userFormData }, (data) ->
              { client, provisioner } = data
              next()

          (next) ->
            fetchMachinesByUsername userFormData.username, (machines) ->
              machine = machines[0]

              # expecting provisioner to be set on machine
              machine.setProvisioner client, provisioner.slug, (err) ->
                expect(err?.message).to.not.exist
                expect(machine.provisioners).to.exist
                expect(machine.provisioners.length).to.be.equal provisionerCount + 1
                next()

        ]

        async.series queue, done


  describe '#share()', ->

    it 'machine should be shared with specified users', (done) ->

      client              = {}
      account             = {}
      userCount           = 0
      userFormData        = generateDummyUserFormData()
      anotherUserFormData = generateDummyUserFormData()

      queue = [

        (next) ->
          withConvertedUser { userFormData }, (data) ->
            { client } = data
            next()

        (next) ->
          withConvertedUser {}, (data) ->
            { userFormData : anotherUserFormData } = data
            next()

        (next) ->
          fetchMachinesByUsername userFormData.username, (machines) ->
            machine = machines[0]
            userCount = machine.users.length

            # expecting machine to be shared with anotherUser
            machine.share client, [anotherUserFormData.username], (err) ->
              expect(err?.message).to.not.exist
              expect(machine.users.length).to.be.equal userCount + 1
              next()

      ]

      async.series queue, done


  describe '#approve()', ->

    it 'should approve client', (done) ->

      machine            = {}
      userInfo           = generateUserInfo()
      machineId          = null
      anotherUser        = {}
      anotherUserAccount = {}

      queue = [

        (next) ->
          createUserAndMachine userInfo, (err, data) ->
            expect(err).to.not.exist
            { machine } = data
            userCount   = machine.users.length
            machineId   = machine._id
            next()

        (next) ->
          JUser.createUser generateUserInfo(), (err, user_, account_) ->
            expect(err).to.not.exist
            anotherUser        = user_
            anotherUserAccount = account_
            next()

        (next) ->
          # sharing maching with another user
          params = { target : [anotherUser.username], asUser : yes }
          machine.shareWith params, (err) ->
            expect(err).to.not.exist
            next()

        (next) ->
          # approving share
          _client =
            connection : { delegate : anotherUserAccount }
            context    : { group    : 'koding' }

          machine.approve _client, (err) ->
            expect(err).to.not.exist
            next()

        (next) ->
          # expecting another user to be approved
          JMachine.one { _id : machineId }, (err, machine) ->
            expect(err?.message).to.not.exist
            expect(machine.users[1].approved).to.be.ok
            next()

      ]

      async.series queue, done


  describe '#deny()', ->

    it 'should deny client', (done) ->

      machine            = {}
      userInfo           = generateUserInfo()
      machineId          = null
      userCount          = 0
      anotherUser        = {}
      anotherUserAccount = {}

      queue = [

        (next) ->
          createUserAndMachine userInfo, (err, data) ->
            expect(err).to.not.exist
            { machine } = data
            userCount   = machine.users.length
            machineId   = machine._id
            next()

        (next) ->
          JUser.createUser generateUserInfo(), (err, user_, account_) ->
            expect(err).to.not.exist
            anotherUser        = user_
            anotherUserAccount = account_
            next()

        (next) ->
          # sharing machine with another user
          params = { target : [anotherUser.username], asUser : yes }
          machine.shareWith params, (err) ->
            expect(err).to.not.exist
            expect(machine.users.length).to.be.equal userCount + 1
            next()

        (next) ->
          # denying share request
          _client =
            connection : { delegate : anotherUserAccount }
            context    : { group    : 'koding' }

          machine.deny _client, (err) ->
            expect(err).to.not.exist
            next()

        (next) ->
          # expecting user not to be added to machine.users
          JMachine.one { _id : machineId }, (err, machine) ->
            expect(err).to.not.exist
            expect(machine.users.length).to.be.equal userCount
            next()

      ]

      async.series queue, done


  describe '#setChannelId()', ->

    client       = {}
    clientGuest  = {}
    userFormData = generateDummyUserFormData()
    machine      = null

    before (done) ->

      async.series [

        (next) ->
          withConvertedUser { userFormData }, (data) ->
            { client } = data
            next()

        (next) ->
          formData = generateDummyUserFormData()
          withConvertedUser { userFormData: formData }, (data) ->
            { client: clientGuest } = data
            next()

        (next) ->
          fetchMachinesByUsername userFormData.username, (machines) ->
            [ machine ] = machines
            next()

      ], done

    it 'should deny set channel id requests for non-owners', (done) ->

      channelId = '123456789123456789'
      machine.setChannelId clientGuest, { channelId }, (err) ->
        expect(err).to.exist
        expect(err.message).to.be.equal 'Access denied'
        expect(machine.channelId).to.not.exist
        done()

    it 'should not allow to set an object as channel id', (done) ->

      expect(machine.channelId).to.not.exist

      channelId = { foo: 'bar' }
      machine.setChannelId client, { channelId }, (err) ->
        expect(err).to.exist
        expect(err.message).to.be.equal 'Invalid ChannelID provided'
        expect(machine.channelId).to.not.exist
        done()

    it 'should not allow to set an invalid channel id', (done) ->

      expect(machine.channelId).to.not.exist

      channelId = 'somefoobarbazinvalidandlongchannelid'
      machine.setChannelId client, { channelId }, (err) ->
        expect(err).to.exist
        expect(err.message).to.be.equal 'Invalid ChannelID provided'
        expect(machine.channelId).to.not.exist
        done()

    it 'should be able set a valid channel id on machine', (done) ->

      expect(machine.channelId).to.not.exist

      channelId = '123456789123456789'
      machine.setChannelId client, { channelId }, (err) ->
        expect(err).to.not.exist
        expect(machine.channelId).to.be.equal channelId
        done()

    it 'should be able to unset channel id on machine', (done) ->

      expect(machine.channelId).to.exist

      machine.setChannelId client, {}, (err, _machine) ->
        expect(err).to.not.exist
        expect(_machine.channelId).to.not.exist
        done()


beforeTests()

runTests()
