{ argv }                      = require 'optimist'
{ expect }                    = require 'chai'
{ env : { MONGO_URL } }       = process

KONFIG                        = require('koding-config-manager').load("main.#{argv.c}")

Bongo                         = require 'bongo'
JUser                         = require '../user/index'
mongo                         = MONGO_URL or "mongodb://#{ KONFIG.mongo }"
JMachine                      = require './machine'

{ daisy }                     = Bongo
{ createUserAndMachine
  generateMachineParams
  generateMachineParamsByAccount } = require '../../../../testhelper/models/machinehelper'

{ generateUserInfo
  generateDummyClient
  generateRandomString
  generateDummyUserFormData } = require '../../../../testhelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  bongo = new Bongo
    root   : __dirname
    mongo  : mongo
    models : ''

  bongo.once 'dbClientReady', ->
    done()


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.machine', ->

  describe '#create()', ->

    it 'when machine data is not valid should return error', (done) ->

      client        = {}
      machineParams = {}

      queue = [

        ->
          # generating a dummy client
          generateDummyClient { group : 'koding' }, (err, client_) ->
            expect(err).to.not.exist
            client = client_
            queue.next()

        ->
          # generating machineParams to use on machine creation
          generateMachineParams client, (err, data) ->
            expect(err).to.not.exist
            machineParams = data
            queue.next()

        ->
          # sending machineParams.user null and expecting error
          machineParams.user = null
          JMachine.create machineParams, (err, data) ->
            expect(err?.message).to.be.equal 'User is not set!'
            queue.next()

        -> done()

      ]

      daisy queue


    describe 'when machine data is valid', ->

      it 'a new machine should be created for revived client', (done) ->

        client        = {}
        machineParams = {}

        queue = [

          ->
            # generating a dummy client
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              queue.next()

          ->
            # generating machineParams to use on machine creation
            generateMachineParams client, (err, data) ->
              expect(err).to.not.exist
              machineParams = data
              queue.next()

          ->
            # expecting machine to be craeted
            JMachine.create machineParams, (err, machine) ->
              expect(err).to.not.exist
              expect(machine.provider).to.be.equal machineParams.provider
              expect(machine.status.state).to.be.equal 'NotInitialized'
              queue.next()

          -> done()

        ]

        daisy queue


      it 'a new machine should be created for created user', (done) ->

        # creating a user and a machine with newly created user
        createUserAndMachine generateUserInfo(), (err, machine, user) ->
          expect(err).to.not.exist
          expect(machine.provider).to.be.equal 'koding'
          expect(machine.status.state).to.be.equal 'NotInitialized'
          expect(machine.users[0].id + '').to.be.equal user.getId() + ''

          done()


  describe '#destroy()', ->

    describe 'when user is the owner', ->

      it 'maching should be destroyed', (done) ->

        user          = {}
        machine       = {}
        userInfo      = generateUserInfo()
        machineCount  = 0

        queue = [

          ->
            createUserAndMachine userInfo, (err, machine_, user_) ->
              expect(err).to.not.exist
              user      = user_
              machine   = machine_
              userCount = machine.users.length
              queue.next()

          ->
            # fetching user's first machine
            JMachine.fetchByUsername userInfo.username, (err, machines) ->
              expect(err).to.not.exist
              machineCount = machines.length
              expect(machineCount).to.be.above 0
              queue.next()

          ->
            # expecting machine to be destroyed without error
            _client = { r : { user } }
            machine.destroy _client, (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            # fetching machine instances again expecting machine to be destroyed
            JMachine.fetchByUsername userInfo.username, (err, machines) ->
              expect(err).to.not.exist
              expect(machines.length).to.be.equal machineCount - 1
              queue.next()

          -> done()

        ]

        daisy queue


    describe 'when user is not the owner', ->

      it 'should return error', (done) ->

        user          = {}
        machine       = {}
        userInfo      = generateUserInfo()
        anotherUser   = {}
        machineCount  = 0

        queue = [

          ->
            createUserAndMachine userInfo, (err, machine_) ->
              expect(err).to.not.exist
              machine = machine_
              userCount = machine.users.length
              queue.next()

          ->
            JUser.createUser generateUserInfo(), (err, user_, account_) ->
              expect(err).to.not.exist
              anotherUser = user_
              queue.next()

          ->
            # expecting destroy attempt with another user to fail
            _client = { r : { user : anotherUser } }
            machine.destroy _client, (err) ->
              expect(err?.message).to.be.equal 'Access denied'
              queue.next()

          -> done()

        ]

        daisy queue


  describe '#addUsers()', ->

    describe 'when data is valid', ->

      it 'should be able to add a new user to machine', (done) ->

        machine       = {}
        userInfo      = generateUserInfo()
        userCount     = 0
        anotherUser   = {}

        queue = [

          ->
            createUserAndMachine userInfo, (err, machine_) ->
              expect(err).to.not.exist
              machine = machine_
              userCount = machine.users.length
              queue.next()

          ->
            JUser.createUser generateUserInfo(), (err, user_, account_) ->
              expect(err).to.not.exist
              anotherUser = user_
              queue.next()

          ->
            # expecting another user to be added
            params =
              targets   : [anotherUser]
              asOwner   : yes
              permanent : yes

            machine.addUsers params, (err) ->
              expect(err).to.not.exist
              expect(machine.users.length).to.be.equal userCount + 1
              queue.next()

          -> done()

        ]

        daisy queue


    describe 'when data is not valid', ->

      it 'should return error if targets.length is greater than limit', (done) ->

        limit         = 50
        queue         = []
        targets       = []
        machine       = {}

        generateAnotherUser = (targets, queue) -> ->
          JUser.createUser generateUserInfo(), (err, user_) ->
            expect(err).to.not.exist
            targets.push user_
            queue.next()

        queue.push ->
          createUserAndMachine generateUserInfo(), (err, machine_) ->
            machine = machine_
            queue.next()

        for i in [0...limit]
          queue.push generateAnotherUser targets, queue

        queue.push ->
          params =
            targets   : targets
            asOwner   : yes
            permanent : yes

          expectedError = "Machine sharing is limited up to #{limit} users."
          machine.addUsers params, (err) ->
            expect(err?.message).to.be.equal expectedError
            queue.next()

        queue.push -> done()

        daisy queue


  describe '#removeUsers()', ->

    describe 'when data is valid', ->

      it 'user should be removed from machine', (done) ->

        queue            = []
        targets          = []
        machine          = {}
        userCount        = 0
        addedUserCount   = 5
        removedUserCount = 2

        generateAnotherUser = (targets, queue) -> ->
          JUser.createUser generateUserInfo(), (err, user_) ->
            expect(err).to.not.exist
            targets.push user_
            queue.next()

        queue.push ->
          createUserAndMachine generateUserInfo(), (err, machine_) ->
            machine = machine_
            userCount = machine.users.length
            queue.next()

        for i in [0...addedUserCount]
          queue.push generateAnotherUser targets, queue

        # first adding users
        queue.push ->
          params =
            targets   : targets
            asOwner   : yes
            permanent : yes

          machine.addUsers params, (err) ->
            expect(err).to.not.exist
            expect(machine.users.length).to.be.equal userCount + addedUserCount
            queue.next()

        # then removing some users and expecting no error
        queue.push ->
          params =
            targets   : targets.slice 0, removedUserCount
            asOwner   : yes
            permanent : yes

          expectedUserCount = userCount + addedUserCount - removedUserCount
          machine.removeUsers params, (err) ->
            expect(err).to.not.exist
            expect(machine.users.length).to.be.equal expectedUserCount
            queue.next()

        queue.push -> done()

        daisy queue


  describe '#shareWith()', ->

    describe 'when data is not valid', ->

      it 'should return error if target is not specified', (done) ->

        machine       = {}
        userInfo      = generateUserInfo()

        queue = [

          ->
            createUserAndMachine userInfo, (err, machine_) ->
              expect(err).to.not.exist
              machine = machine_
              queue.next()

          ->
            # expecting error when target is not specified
            params = { target : null }
            machine.shareWith params, (err, machine_) ->
              expect(err?.message).to.be.equal 'Target required.'
              queue.next()

          -> done()

        ]

        daisy queue


      it 'should return error if target is not an instance of juser', (done) ->

        machine       = {}
        userInfo      = generateUserInfo()

        queue = [

          ->
            createUserAndMachine userInfo, (err, machine_) ->
              expect(err).to.not.exist
              machine = machine_
              queue.next()

          ->
            # expecting error when target is invalid
            params = { target : ['invalidTarget'] }
            machine.shareWith params, (err, machine_) ->
              expect(err?.message).to.be.equal 'Target does not support machines.'
              queue.next()

          -> done()

        ]

        daisy queue

    describe 'when data is valid', ->

      it 'should share machine if asUser is truthy', (done) ->

        machine       = {}
        userInfo      = generateUserInfo()
        userCount     = 0
        anotherUser   = {}

        queue = [

          ->
            createUserAndMachine userInfo, (err, machine_) ->
              expect(err).to.not.exist
              machine = machine_
              userCount = machine.users.length
              queue.next()

          ->
            JUser.createUser generateUserInfo(), (err, user_) ->
              expect(err).to.not.exist
              anotherUser = user_
              queue.next()

          ->
            # expecting user to be added when asUser is yes
            params = { target : [anotherUser.username], asUser : yes }
            machine.shareWith params, (err) ->
              expect(err).to.not.exist
              expect(machine.users.length).to.be.equal userCount + 1
              queue.next()

          ->
            # expecting user to be removed when asUser is no
            params = { target : [anotherUser.username], asUser : no }
            machine.shareWith params, (err) ->
              expect(err).to.not.exist
              expect(machine.users.length).to.be.equal userCount
              queue.next()

          -> done()

        ]

        daisy queue


  describe '#fetchOwner()', ->

    it 'should return error when there is no owner', (done) ->

      machine       = {}
      userInfo      = generateUserInfo()
      userCount     = 0

      queue = [

        ->
          createUserAndMachine userInfo, (err, machine_, user_) ->
            expect(err).to.not.exist
            machine = machine_
            queue.next()

        ->
          # setting machine owner to false
          machine.update { $set : { 'users.0.owner' : no } }, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # expecting error when there is no owner
          machine.fetchOwner (err) ->
            expect(err?.message).to.be.equal 'Owner user not found'
            queue.next()

        -> done()

      ]

      daisy queue


    it 'should return the owner when data is valid', (done) ->

      user          = {}
      machine       = {}
      userInfo      = generateUserInfo()
      userCount     = 0

      queue = [

        ->
          createUserAndMachine userInfo, (err, machine_, user_) ->
            expect(err).to.not.exist
            user    = user_
            machine = machine_
            queue.next()

        ->
          # expecting owner to be fetched
          machine.fetchOwner (err, owner) ->
            expect(err).to.not.exist
            expect(owner).to.exist
            expect(owner.profile.nickname).to.be.equal user.username
            queue.next()

        -> done()

      ]

      daisy queue


  describe '#one$()', ->

    it 'should fetch machine instance', (done) ->

      user             = {}
      client           = {}
      machine          = {}
      account          = {}
      userFormData     = generateDummyUserFormData()

      queue = [

        ->
          # generating a dummy client
          generateDummyClient { group : 'koding' }, (err, client_) ->
            expect(err).to.not.exist
            client = client_
            queue.next()

        ->
          # registering a new user
          JUser.convert client, userFormData, (err, data) ->
            expect(err).to.not.exist
            { account, newToken }      = data
            client.sessionToken        = newToken
            client.connection.delegate = account
            queue.next()

        ->
          # fetching machine instance of newly registered user
          JMachine.fetchByUsername userFormData.username, (err, machines) ->
            expect(err).to.not.exist
            machine = machines[0]
            queue.next()

        ->
          # expecting machine to be fetched by machine id and client
          JMachine.one$ client, machine._id + '', (err, machine_) ->
            expect(err).to.not.exist
            expect(machine).to.exist
            expect(machine._id + '').to.be.equal machine_._id + ''
            queue.next()

        -> done()

      ]

      daisy queue


  describe '#reviveUsers()', ->

    describe 'when data is not valid', ->

      it 'should return error if user is not owner', (done) ->

        client           = {}
        machine          = {}
        account          = {}
        userFormData     = generateDummyUserFormData()
        anotherClient    = {}

        queue = [

          ->
            # generating a dummy client
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              queue.next()

          ->
            # registering a new user
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist
              { account, newToken }      = data
              client.sessionToken        = newToken
              client.connection.delegate = account
              queue.next()

          ->
            # generating client for another user
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              anotherClient = client_
              queue.next()

          ->
            # registering another user
            JUser.convert anotherClient, generateDummyUserFormData(), (err, data) ->
              expect(err).to.not.exist
              queue.next()

          ->
            # fetching owner user's machine
            JMachine.fetchByUsername userFormData.username, (err, machines) ->
              expect(err).to.not.exist
              machine = machines[0]
              queue.next()

          ->
            # expecting error when another user attempts to revive users
            machine.reviveUsers anotherClient, {}, (err) ->
              expect(err?.message).to.be.equal 'Access denied'
              queue.next()

          -> done()

        ]

        daisy queue


    describe 'when data is valid', ->

      it 'should revive users', (done) ->

        client           = {}
        machine          = {}
        account          = {}
        userFormData     = generateDummyUserFormData()

        queue = [

          ->
            # generating a dummy client
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              queue.next()

          ->
            # registering a new user
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist
              { account, newToken }      = data
              client.sessionToken        = newToken
              client.connection.delegate = account
              queue.next()

          ->
            # fetching machine of owner user
            JMachine.fetchByUsername userFormData.username, (err, machines) ->
              expect(err).to.not.exist
              machine = machines[0]
              queue.next()

          ->
            # expecting to revive users without error
            machine.reviveUsers client, {}, (err) ->
              expect(err?.message).to.not.exist
              queue.next()

          -> done()

        ]

        daisy queue


  describe '#setLabel()', ->

    describe 'when data is not valid', ->

      it 'should return error if user is not owner or label is empty', (done) ->

        client           = {}
        machine          = {}
        account          = {}
        userFormData     = generateDummyUserFormData()
        anotherClient    = {}

        queue = [

          ->
            # generating a dummy client
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              queue.next()

          ->
            # registering a new user
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist
              { account, newToken }      = data
              client.sessionToken        = newToken
              client.connection.delegate = account
              queue.next()

          ->
            # generating a dummy client for another user
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              anotherClient = client_
              queue.next()

          ->
            # registering another user
            JUser.convert anotherClient, generateDummyUserFormData(), (err, data) ->
              expect(err).to.not.exist
              queue.next()

          ->
            # fetching machine of user
            JMachine.fetchByUsername userFormData.username, (err, machines) ->
              expect(err).to.not.exist
              machine = machines[0]
              queue.next()

          ->
            # expecting error when another user makes setLabel request
            machine.setLabel anotherClient, 'someLabel', (err) ->
              expect(err?.message).to.be.equal 'Access denied'
              queue.next()

          ->
            # expecting error when label is empty
            machine.setLabel client, '', (err) ->
              expect(err?.message).to.be.equal 'Nickname cannot be empty'
              queue.next()

          -> done()

        ]

        daisy queue


    describe 'when data is valid', ->

      it 'should be able set label on machine', (done) ->

        client           = {}
        machine          = {}
        account          = {}
        userFormData     = generateDummyUserFormData()

        queue = [

          ->
            # generating a dummy client
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              queue.next()

          ->
            # registering user
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist
              { account, newToken }      = data
              client.sessionToken        = newToken
              client.connection.delegate = account
              queue.next()

          ->
            # fetching machine of user
            JMachine.fetchByUsername userFormData.username, (err, machines) ->
              expect(err).to.not.exist
              machine = machines[0]
              queue.next()

          ->
            # generating random label and expecting machine label to be set to it
            newLabel = generateRandomString()
            machine.setLabel client, newLabel, (err) ->
              expect(err).to.not.exist
              expect(machine.label).to.be.equal newLabel
              queue.next()

          -> done()

        ]

        daisy queue


  describe '#setProvisioner()', ->

    describe 'when data is not valid', ->

      it 'should return error when user is not owner', (done) ->

        user               = {}
        machine            = {}
        anotherUserAccount = {}

        queue = [

          ->
            createUserAndMachine generateUserInfo(), (err, machine_, user_) ->
              expect(err).to.not.exist
              user    = user_
              machine = machine_
              queue.next()

          ->
            JUser.createUser generateUserInfo(), (err, user_, account_) ->
              expect(err).to.not.exist
              anotherUserAccount = account_
              queue.next()

          ->
            # expecting error when another user makes request
            _client =
              connection : { delegate : anotherUserAccount }
              context    : { group    : 'koding' }

            machine.setProvisioner _client, '', (err) ->
              expect(err?.message).to.be.equal 'Access denied'
              queue.next()

          -> done()

        ]

        daisy queue


    describe 'when data is valid', ->

      it 'should set provisioner when user is the owner', (done) ->

        user             = {}
        client           = {}
        machine          = {}
        account          = {}
        userFormData     = generateDummyUserFormData()
        provisionerCount = 0

        queue = [

          ->
            # generating a dummy client
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              queue.next()

          ->
            # registering a new user
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist
              { account, newToken }      = data
              client.sessionToken        = newToken
              client.connection.delegate = account
              queue.next()

          ->
            # fetching machine of user
            JMachine.fetchByUsername userFormData.username, (err, machines) ->
              expect(err).to.not.exist
              machine = machines[0]
              queue.next()

          ->
            # expecting provisioner to be set on machine
            machine.setProvisioner client, 'devrim/koding-base', (err) ->
              expect(err?.message).to.not.exist
              expect(machine.provisioners).to.exist
              expect(machine.provisioners.length).to.be.equal provisionerCount + 1
              queue.next()

          -> done()

        ]

        daisy queue


  describe '#share()', ->

    it 'machine should be shared with specified users', (done) ->

      client              = {}
      machine             = {}
      account             = {}
      userCount           = 0
      userFormData        = generateDummyUserFormData()
      anotherClient       = {}
      anotherUserFormData = generateDummyUserFormData()

      queue = [

        ->
          # generating a dummy client
          generateDummyClient { group : 'koding' }, (err, client_) ->
            expect(err).to.not.exist
            client = client_
            queue.next()

        ->
          # registering a new user
          JUser.convert client, userFormData, (err, data) ->
            expect(err).to.not.exist
            { account, newToken }      = data
            client.sessionToken        = newToken
            client.connection.delegate = account
            queue.next()

        ->
          # generating a dummy client for another user
          generateDummyClient { group : 'koding' }, (err, client_) ->
            expect(err).to.not.exist
            anotherClient = client_
            queue.next()

        ->
          # registering another user
          JUser.convert anotherClient, anotherUserFormData, (err, data) ->
            expect(err).to.not.exist
            { account, newToken }             = data
            anotherClient.sessionToken        = newToken
            anotherClient.connection.delegate = account
            queue.next()

        ->
          # fetching machine of user
          JMachine.fetchByUsername userFormData.username, (err, machines) ->
            expect(err).to.not.exist
            machine = machines[0]
            userCount = machine.users.length
            queue.next()

        ->
          # expecting machine to be shared with anotherUser
          machine.share client, [anotherUserFormData.username], (err) ->
            expect(err?.message).to.not.exist
            expect(machine.users.length).to.be.equal userCount + 1
            queue.next()

        -> done()

      ]

      daisy queue


  describe '#approve()', ->

    it 'should approve client', (done) ->

      machine            = {}
      userInfo           = generateUserInfo()
      machineId          = null
      anotherUser        = {}
      anotherUserAccount = {}

      queue = [

        ->
          createUserAndMachine userInfo, (err, machine_) ->
            expect(err).to.not.exist
            machine   = machine_
            userCount = machine.users.length
            machineId = machine._id
            queue.next()

        ->
          JUser.createUser generateUserInfo(), (err, user_, account_) ->
            expect(err).to.not.exist
            anotherUser        = user_
            anotherUserAccount = account_
            queue.next()

        ->
          # sharing maching with another user
          params = { target : [anotherUser.username], asUser : yes }
          machine.shareWith params, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # approving share
          _client =
            connection : { delegate : anotherUserAccount }
            context    : { group    : 'koding' }

          machine.approve _client, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # expecting another user to be approved
          JMachine.one { _id : machineId }, (err, machine) ->
            expect(err?.message).to.not.exist
            expect(machine.users[1].approved).to.be.ok
            queue.next()

        -> done()

      ]

      daisy queue


  describe '#deny()', ->

    it 'should deny client', (done) ->

      machine            = {}
      userInfo           = generateUserInfo()
      machineId          = null
      userCount          = 0
      anotherUser        = {}
      anotherUserAccount = {}

      queue = [

        ->
          createUserAndMachine userInfo, (err, machine_) ->
            expect(err).to.not.exist
            machine   = machine_
            userCount = machine.users.length
            machineId = machine._id
            queue.next()

        ->
          JUser.createUser generateUserInfo(), (err, user_, account_) ->
            expect(err).to.not.exist
            anotherUser        = user_
            anotherUserAccount = account_
            queue.next()

        ->
          # sharing machine with another user
          params = { target : [anotherUser.username], asUser : yes }
          machine.shareWith params, (err) ->
            expect(err).to.not.exist
            expect(machine.users.length).to.be.equal userCount + 1
            queue.next()

        ->
          # denying share request
          _client =
            connection : { delegate : anotherUserAccount }
            context    : { group    : 'koding' }

          machine.deny _client, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # expecting user not to be added to machine.users
          JMachine.one { _id : machineId }, (err, machine) ->
            expect(err).to.not.exist
            expect(machine.users.length).to.be.equal userCount
            queue.next()

        -> done()

      ]

      daisy queue


beforeTests()

runTests()


