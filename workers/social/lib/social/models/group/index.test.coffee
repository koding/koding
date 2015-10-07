{ argv }                      = require 'optimist'
{ expect }                    = require 'chai'
{ env : { MONGO_URL } }       = process
KONFIG                        = require('koding-config-manager').load("main.#{argv.c}")
mongo                         = MONGO_URL or "mongodb://#{ KONFIG.mongo }"
Bongo                         = require 'bongo'
{ daisy }                     = Bongo
JUser                         = require '../user'
JGroup                        = require './index'
JAccount                      = require '../account'
JSession                      = require '../session'
JInvitation                   = require '../invitation'
{ Relationship }              = require 'jraphical'
{ generateRandomEmail
  generateDummyClient
  generateRandomString
  generateDummyUserFormData } = require '../../../../testhelper'


# making sure we have mongo connection before tests
beforeTests = -> before (done) ->

  bongo = new Bongo
    root   : __dirname
    mongo  : mongo
    models : ''

  bongo.once 'dbClientReady', ->
    done()


# here we have actual tests
runTests = -> describe 'workers.social.group.index', ->

  describe '#kickMember()', ->

    describe 'when group slug is koding', ->

      kodingGroup = {}

      before (done) ->

        # fetching koding group
        JGroup.one { slug : 'koding' }, (err, group_) ->
          expect(err).to.not.exist
          kodingGroup = group_
          done()


      it 'should pass error if client doesnt have permission to kick', (done) ->

        client  = {}
        account = {}

        queue = [

          ->
            # generating client
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client  = client_
              account = client.connection.delegate
              queue.next()

          ->
            # expecting error to exist
            kodingGroup.kickMember client, account._id, (err) ->
              expect(err?.message).to.be.equal 'Access denied'
              queue.next()

          -> done()

        ]

        daisy queue


    describe 'when group slug is not koding', ->

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
            # creating a new group
            JGroup.create adminClient, groupData, adminAccount, (err, group_) ->
              expect(err).to.not.exist
              group = group_
              queue.next()

          -> done()

        ]

        daisy queue


      it 'should pass error if user tries kick own account', (done) ->

        # expecting not to be able to kick own account
        expectedError = 'You cannot kick yourself, try leaving the group!'
        group.kickMember adminClient, adminAccount._id, (err) ->
          expect(err?.message).to.be.equal expectedError
          done()


      it 'should be able to kick member if client has permission', (done) ->

        client       = {}
        account      = {}
        userFormData = generateDummyUserFormData()

        queue = [

          ->
            # generating a client which will be kicked from the group
            generateDummyClient { group : groupSlug }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              queue.next()

          ->
            # registering client
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist
              { account, newToken }   = data
              queue.next()

          ->
            # making sure client is a member of the group before trying to kick
            group.searchMembers adminClient, userFormData.username, {}, (err, members) ->
              expect(err).to.not.exist
              expect(members.length).to.be.equal 1
              queue.next()

          ->
            # expecting session to exist before kicking member
            params =
              username  : account.profile.nickname
              groupName : client.context.group

            JSession.one params, (err, data) ->
              expect(err).to.not.exist
              expect(data).to.exist
              expect(data).to.be.an 'object'
              queue.next()

          ->
            # expecting no error from kick member request
            group.kickMember adminClient, account._id, (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            # admin client search for kicked member within group member
            group.searchMembers adminClient, userFormData.username, {}, (err, members) ->
              expect(err).to.not.exist
              expect(members.length).to.be.equal 0
              queue.next()

          ->
            # expecting session to be deleted after kicking member
            params =
              username  : account.profile.nickname
              groupName : client.context.group

            JSession.one params, (err, data) ->
              expect(err).to.not.exist
              expect(data).to.not.exist
              queue.next()

          ->
            # we cannot add blocked user to group
            group.approveMember account, (err) ->
              expect(err).to.exist
              expect(err.message).to.be.equal 'This account is blocked'
              queue.next()

          ->
            # we should be able to unblock the member
            group.unblockMember adminClient, account.getId(), (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            # unblocked member can be added again
            group.approveMember account, (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            done()

        ]

        daisy queue


  describe '#searchMembers()', ->

    describe 'if username is unregistered', ->

      it 'should not fetch any data', (done) ->

        group    = {}
        client   = {}
        username = 'someRandomNonExistingUsername'

        queue = [

          ->
            # generating client which well make searchMembers request
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              queue.next()

          ->
            # fetching koding group
            JGroup.one { slug : 'koding' }, (err, group_) ->
              expect(err).to.not.exist
              group = group_
              queue.next()

          ->
            # expecting to not be able to fetch members data
            group.searchMembers client, username, {}, (err, members) ->
              expect(err).to.not.exist
              expect(members.length).to.be.equal 0
              queue.next()

          -> done()

        ]

        daisy queue


    describe 'if username is registered', ->

      it 'should be able to fetch by username for koding group slug', (done) ->

        group             = {}
        client            = {}
        userFormData      = generateDummyUserFormData()

        groupData         =
          slug           : 'koding'
          title          : generateRandomString()
          visibility     : 'visible'
          allowedDomains : [ 'koding.com' ]

        queue = [

          ->
            # fetching group
            JGroup.one { slug : 'koding' }, (err, group_) ->
              expect(err).to.not.exist
              group = group_
              queue.next()

          ->
            # generating client which well make searchMembers request
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              queue.next()

          ->
            # registering user
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist
              queue.next()

          ->
            # expecting to find newly registered member
            group.searchMembers client, userFormData.username, {}, (err, members) ->
              expect(err).to.not.exist
              expect(members.length).to.be.equal 1
              expect(members[0].profile.nickname).to.be.equal userFormData.username
              queue.next()

          -> done()

        ]

        daisy queue


      describe 'when group is not koding', (done) ->

        group             = {}
        client            = {}
        account           = {}
        groupSlug         = generateRandomString()
        adminClient       = {}

        groupData         =
          slug           : groupSlug
          title          : generateRandomString()
          visibility     : 'visible'
          allowedDomains : [ 'koding.com' ]

        # before running test cases creating a group
        before (done) ->

          adminAccount      = {}
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
              # creating a new group
              JGroup.create adminClient, groupData, adminAccount, (err, group_) ->
                expect(err).to.not.exist
                group = group_
                queue.next()

            -> done()

          ]

          daisy queue


        it 'should not be able to fetch search result if not a member of group', (done) ->

          client       = {}
          userFormData = generateDummyUserFormData()

          queue = [

            ->
              # generating client which will make search member request
              generateDummyClient { group : 'koding' }, (err, client_) ->
                expect(err).to.not.exist
                client = client_
                queue.next()

            ->
              # expecting not to be able to fetch member data
              group.searchMembers client, userFormData.username, {}, (err, members) ->
                expect(err?.message).to.be.equal 'Access denied'
                queue.next()

            -> done()

          ]

          daisy queue


        it 'should be able to fetch member data after registering to group', (done) ->

          client       = {}
          userFormData = generateDummyUserFormData()

          queue = [

            ->
              # generating client which will make search member request
              generateDummyClient { group : groupSlug }, (err, client_) ->
                expect(err).to.not.exist
                client = client_
                queue.next()

            ->
              # registering client
              JUser.convert client, userFormData, (err, data) ->
                expect(err).to.not.exist
                { account, newToken }   = data

                # set credentials
                client.sessionToken        = newToken
                client.connection.delegate = account
                queue.next()

            ->
              # expecting new member client to be able fetch self data
              group.searchMembers client, userFormData.username, {}, (err, members) ->
                expect(err).to.not.exist
                expect(members[0].profile.nickname).to.be.equal userFormData.username
                queue.next()

            ->
              # expecting admin to be able to fetch new member's data
              group.searchMembers adminClient, userFormData.username, {}, (err, members) ->
                expect(err).to.not.exist
                expect(members[0].profile.nickname).to.be.equal userFormData.username
                queue.next()

            -> done()

          ]

          daisy queue


  describe '#isInAllowedDomain()', ->

    it 'should return true if group slug is koding', (done) ->

      client            = {}
      account           = {}
      groupSlug         = 'koding'
      userFormData      = generateDummyUserFormData()

      groupData         =
        slug           : groupSlug
        title          : generateRandomString()
        visibility     : 'visible'
        allowedDomains : [ 'koding.com' ]

      queue = [

        ->
          # generating client
          generateDummyClient { group : 'koding' }, (err, client_) ->
            expect(err).to.not.exist
            client = client_
            queue.next()

        ->
          # registering user
          JUser.convert client, userFormData, (err, data) ->
            expect(err).to.not.exist
            { account } = data
            queue.next()

        ->
          # expecting to return true for any domain
          JGroup.one { slug : groupSlug }, (err, group) ->
            expect(err).to.not.exist
            expect(group.isInAllowedDomain 'someRandomDomain').to.be.ok
            queue.next()

        -> done()

      ]

      daisy queue


    it 'should return false if group does not have allowedDomains', (done) ->

      client            = {}
      account           = {}
      groupSlug         = generateRandomString()
      userFormData      = generateDummyUserFormData()

      groupData         =
        slug           : groupSlug
        title          : generateRandomString()
        visibility     : 'visible'
        allowedDomains : []

      queue = [

        ->
          # generating client
          generateDummyClient { group : 'koding' }, (err, client_) ->
            expect(err).to.not.exist
            client = client_
            queue.next()

        ->
          # registering user
          JUser.convert client, userFormData, (err, data) ->
            expect(err).to.not.exist
            { account } = data
            queue.next()

        ->
          # expecting to return false when there are no allowedDomains
          JGroup.create client, groupData, account, (err, group) ->
            expect(err).to.not.exist
            expect(group.isInAllowedDomain 'someRandomDomain').not.to.be.ok
            queue.next()

        -> done()

      ]

      daisy queue


    it 'should return true if group is in allowedDomains', (done) ->

      client            = {}
      account           = {}
      groupSlug         = generateRandomString()
      userFormData      = generateDummyUserFormData()

      groupData         =
        slug           : groupSlug
        title          : generateRandomString()
        visibility     : 'visible'
        allowedDomains : ['gmail.com']

      allowedDomainEmail = generateRandomEmail groupData.allowedDomains[0]

      queue = [

        ->
          # generating client
          generateDummyClient { group : 'koding' }, (err, client_) ->
            expect(err).to.not.exist
            client = client_
            queue.next()

        ->
          # registering user
          JUser.convert client, userFormData, (err, data) ->
            expect(err).to.not.exist
            { account } = data
            queue.next()

        ->
          # expecting to return false when there are no allowedDomains
          JGroup.create client, groupData, account, (err, group) ->
            expect(err).to.not.exist
            expect(group.isInAllowedDomain allowedDomainEmail).to.be.ok
            queue.next()

        -> done()

      ]

      daisy queue


  describe '#create()', ->

    describe 'when group data is valid', ->

      it 'should be able to create group', (done) ->

        group             = {}
        client            = {}
        account           = {}
        groupSlug         = generateRandomString()
        groupTitle        = generateRandomString()
        userFormData      = generateDummyUserFormData()

        groupData         =
          slug           : groupSlug
          title          : groupTitle
          visibility     : 'visible'
          allowedDomains : [ 'koding.com' ]

        queue = [

          ->
            # generating client
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              queue.next()

          ->
            # registering user
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist
              { account } = data
              queue.next()

          ->
            # expecting group to be created successfully
            JGroup.create client, groupData, account, (err, group_) ->
              expect(err)                  .to.not.exist
              group = group_
              expect(group.slug)           .to.be.equal groupSlug
              expect(group.title)          .to.be.equal groupTitle
              expect(group.visibility)     .to.be.equal groupData.visibility
              expect(group.allowedDomains) .to.include groupData.allowedDomains[0]
              queue.next()

          ->
            # expecting owner account and group relationship to be created
            params =
              $and : [
                { as       : 'owner' }
                { sourceId : group._id }
                { targetId : account._id }
              ]

            # expecting relationship to be created
            Relationship.one params, (err, relationship) ->
              expect(err)          .to.not.exist
              expect(relationship) .to.exist
              queue.next()

          ->
            # expecting account to be saved as a member
            params =
              $and : [
                { as       : 'member' }
                { sourceId : group._id }
                { targetId : account._id }
              ]

            Relationship.one params, (err, relationship) ->
              expect(err)          .to.not.exist
              expect(relationship) .to.exist
              queue.next()

          -> done()

        ]

        daisy queue


    describe 'when group data is not valid', ->

      it 'should pass error if slug is empty or set as koding', (done) ->

        client            = {}
        account           = {}
        userFormData      = generateDummyUserFormData()

        groupData         =
          slug       : ''
          title      : generateRandomString()
          visibility : 'visible'

        queue = [

          ->
            # generating client
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              queue.next()

          ->
            # registering user
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist
              { account } = data
              queue.next()

          ->
            # expecting error for 'koding' slug
            groupData.slug = 'koding'

            expectedError = 'The slug koding is not available.'
            JGroup.create client, groupData, account, (err, data) ->
              expect(err?.message).to.be.equal expectedError
              queue.next()

          ->
            # expecting validaton error when slug is empty
            groupData.slug = ''

            JGroup.create client, groupData, account, (err, data) ->
              expect(err).to.exist
              queue.next()

          -> done()

        ]

        daisy queue


      it 'should pass error if slug is in use', (done) ->

        client            = {}
        account           = {}
        groupSlug         = generateRandomString()
        userFormData      = generateDummyUserFormData()

        groupData         =
          slug       : groupSlug
          title      : generateRandomString()
          visibility : 'visible'

        queue = [

          ->
            # generating client
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              queue.next()

          ->
            # registering user
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist
              { account } = data
              queue.next()

          ->
            # expecting group to be created
            JGroup.create client, groupData, account, (err, data) ->
              expect(err).to.not.exist
              queue.next()

          ->
            # expecting error using already claimed slug
            JGroup.create client, groupData, account, (err, data) ->
              expect(err?.message).to.be.equal "The slug #{groupSlug} is not available."
              queue.next()

          -> done()

        ]

        daisy queue


beforeTests()

runTests()


