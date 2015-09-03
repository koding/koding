{ argv }                      = require 'optimist'
{ expect }                    = require 'chai'
{ env : { MONGO_URL } }       = process

KONFIG                        = require('koding-config-manager').load("main.#{argv.c}")

Bongo                         = require 'bongo'
JUser                         = require './user'
mongo                         = MONGO_URL or "mongodb://#{ KONFIG.mongo }"
JAccount                      = require './account'
JSession                      = require './session'
TestHelper                    = require '../../../testhelper'

{ daisy }                     = Bongo
{ generateUserInfo
  generateDummyClient
  generateCredentials
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  generateDummyUserFormData } = TestHelper


# making sure we have db connection before tests
beforeTests = -> before (done) ->

  bongo = new Bongo
    root   : __dirname
    mongo  : mongo
    models : ''

  bongo.once 'dbClientReady', ->
    done()


# here we have actual tests
runTests = -> describe 'workers.social.user.account', ->

  describe '#modify()', ->

    it 'should pass error if fields contain invalid key', (done) ->

      client       = null
      account      = null
      fields       = { someInvalidField : 'someInvalidField' }
      userFormData = generateDummyUserFormData()

      queue = [

        ->
          # generating dummy client
          generateDummyClient { group : 'koding' }, (err, client_) ->
            expect(err).to.not.exist
            client  = client_
            account = client.connection.delegate
            queue.next()

        ->
          # registering user
          JUser.convert client, userFormData, (err, data) ->
            expect(err).to.not.exist
            # set credentials
            { account, newToken }      = data
            client.sessionToken        = newToken
            client.connection.delegate = account
            queue.next()

        ->
          # expecting error when using unallowed field
          account.modify client, fields, (err) ->
            expect(err?.message).to.be.equal 'Modify fields is not valid'
            queue.next()

        -> done()

      ]

      daisy queue


    it 'should update given fields correctly', (done) ->

      fields =
        'profile.about'     : 'newAbout'
        'profile.lastName'  : 'newLastName'
        'profile.firstName' : 'newFirstName'

      client        = null
      account       = null
      userFormData  = generateDummyUserFormData()

      queue = [

        ->
          # generating dummy client
          generateDummyClient { group : 'koding' }, (err, client_) ->
            expect(err).to.not.exist
            client  = client_
            account = client.connection.delegate
            queue.next()

        ->
          # registering user
          JUser.convert client, userFormData, (err, data) ->
            expect(err).to.not.exist
            # set credentials
            { account, newToken }      = data
            client.sessionToken        = newToken
            client.connection.delegate = account
            queue.next()

        ->
          # expecting account to be modified
          account.modify client, fields, (err, data) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # expecting account's values to be changed
          for key, value of fields
            expect(account.getAt key).to.be.equal value
          queue.next()

        -> done()

      ]

      daisy queue


  describe '#createSocialApiId()', ->

    describe 'when account type is unregistered', ->

      it 'should return -1', (done) ->

        client        = null
        account       = null
        userFormData  = generateDummyUserFormData()

        queue = [

          ->
            # generating dummy client
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client  = client_
              account = client.connection.delegate
              queue.next()

          ->
            # expecting unregistered account to return -1
            account.createSocialApiId (err, socialApiId) ->
              expect(err)          .to.not.exist
              expect(socialApiId)  .to.be.equal -1
              queue.next()

          -> done()

        ]

        daisy queue


    describe 'when account type is not unregistered', ->

      it 'should return socialApiId if socialApiId is already set', (done) ->

        client        = null
        account       = null
        socialApiId   = '12345'
        userFormData  = generateDummyUserFormData()

        queue = [

          ->
            # generating dummy client
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client  = client_
              account = client.connection.delegate
              queue.next()

          ->
            # registering user
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist
              # set credentials
              { account, newToken }      = data
              client.sessionToken        = newToken
              client.connection.delegate = account
              queue.next()

          ->
            # setting social api id
            account.update { $set : { socialApiId : socialApiId } }, (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            # expecting createsocialApiId method to return accountId
            account.createSocialApiId (err, socialApiId_) ->
              expect(err)          .to.not.exist
              expect(socialApiId_) .to.be.equal socialApiId
              queue.next()

          -> done()

        ]

        daisy queue


      it 'should create social api id if account\'s socialApiId is not set', (done) ->

        client        = null
        account       = null
        userFormData  = generateDummyUserFormData()

        queue = [

          ->
            # generating dummy client
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client  = client_
              account = client.connection.delegate
              queue.next()

          ->
            # registering user
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist
              # set credentials
              { account, newToken }      = data
              client.sessionToken        = newToken
              client.connection.delegate = account
              queue.next()

          ->
            # unsetting account's socialApiId
            account.socialApiId = null
            account.update { $unset : { 'socialApiId' : 1 } }, (err) ->
              expect(err)                          .to.not.exist
              expect(account.getAt 'socialApiId')  .to.not.exist
              queue.next()

          ->
            # creating new social api id
            account.createSocialApiId (err, socialApiId_) ->
              expect(err)           .to.not.exist
              expect(socialApiId_)  .to.exist
              queue.next()

          ->
            # expecting account's social api id to be set
            expect(account.getAt 'socialApiId')  .to.exist
            expect(account.socialApiId)          .to.exist
            queue.next()

          -> done()

        ]

        daisy queue


  describe '#fetchMyPermissions()', ->

    describe 'when group does not exist', ->

      it 'should return error', (done) ->

        client        = null
        account       = null
        userFormData  = generateDummyUserFormData()

        queue = [

          ->
            # generating dummy client
            generateDummyClient { group : 'someInvalidGroup' }, (err, client_) ->
              expect(err).to.not.exist
              client  = client_
              account = client.connection.delegate
              queue.next()

          ->
            # expecting error when client's group does not exist
            account.fetchMyPermissions client, (err, permissions) ->
              expect(err?.message).to.be.equal 'group not found'
              queue.next()

          -> done()

        ]

        daisy queue


    describe 'when group exists', ->

      describe 'if account is valid', ->

        it 'should return client\'s permissions', (done) ->

          client        = null
          account       = null
          userFormData  = generateDummyUserFormData()

          queue = [

            ->
              # generating dummy client
              generateDummyClient { group : 'koding' }, (err, client_) ->
                expect(err).to.not.exist
                client  = client_
                account = client.connection.delegate
                queue.next()

            ->
              # expecting to be able to get permissions
              account.fetchMyPermissions client, (err, permissions) ->
                expect(err)          .to.not.exist
                expect(permissions)  .to.exist
                expect(permissions)  .to.be.an 'object'
                queue.next()

            -> done()

          ]

          daisy queue

      describe 'if group slug is not defined', ->

        it 'should set the slug as koding and return permissions', (done) ->

          client        = null
          account       = null
          userFormData  = generateDummyUserFormData()

          queue = [

            ->
              # generating dummy client
              generateDummyClient { group : 'koding' }, (err, client_) ->
                expect(err).to.not.exist
                client               = client_
                client.context.group = null
                account              = client.connection.delegate
                queue.next()

            ->
              # expecting to be able to get permissions
              account.fetchMyPermissions client, (err, permissions) ->
                expect(err)          .to.not.exist
                expect(permissions)  .to.exist
                expect(permissions)  .to.be.an 'object'
                queue.next()

            -> done()

          ]

          daisy queue

  describe '#leaveFromAllGroups()', ->

    describe 'when group does exists', ->

      group             = {}
      groupSlug         = generateRandomString()
      adminClient       = {}
      adminAccount      = {}

      groupData         =
        slug           : groupSlug
        title          : generateRandomString()
        visibility     : 'visible'
        allowedDomains : [ 'koding.com' ]

      # before running test cases creating a group
      before (done) ->

        adminUserFormData = generateDummyUserFormData()

        queue = [

          ->
            # generating admin client to create group
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              adminClient = client_
              queue.next()

          ->
            # registering admin client
            JUser.convert adminClient, adminUserFormData, (err, data) ->
              expect(err).to.not.exist
              { account, newToken } = data

              # set credentials
              adminClient.sessionToken        = newToken
              adminClient.connection.delegate = account
              adminClient.context.group       = groupSlug
              adminAccount                    = account
              queue.next()

          ->
            JGroup = require './group'
            # creating a new group
            JGroup.create adminClient, groupData, adminAccount, (err, group_) ->
              expect(err).to.not.exist
              group = group_
              queue.next()

          -> done()

        ]

        daisy queue


      it 'admin should have more than one group', (done) ->

        adminAccount.fetchAllParticipatedGroups adminClient, (err, groups) ->
          expect(err).to.not.exist
          expect(groups).to.have.length.above(1)
          done()

      it 'standart user should be able to leave from all groups', (done) ->
        client       = null
        account      = null
        userFormData = generateDummyUserFormData()

        queue = [

          ->
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              queue.next()

          ->
            # registering admin client
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist
              { account, newToken } = data

              client.sessionToken        = newToken
              client.connection.delegate = account
              client.context.group       = 'koding'
              queue.next()

          ->
            JUser = require './user'
            JUser.addToGroup account, group.slug, userFormData.email, null, (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            account.fetchAllParticipatedGroups client, (err, groups) ->
              expect(err).to.not.exist
              expect(groups).to.have.length.above(1)
              queue.next()

          ->
            account.leaveFromAllGroups client, (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            account.fetchAllParticipatedGroups client, (err, groups) ->
              expect(err).to.not.exist
              expect(groups).to.have.length(1)
              queue.next()

          ->
            done()

        ]

        daisy queue

beforeTests()

runTests()


