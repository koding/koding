JUser                         = require '../user'
JGroup                        = require './index'
JAccount                      = require '../account'
JSession                      = require '../session'
JApiToken                     = require '../apitoken'
JInvitation                   = require '../invitation'
{ async
  daisy
  expect
  expectRelation
  withDummyClient
  withConvertedUser
  expectAccessDenied
  generateRandomEmail
  generateDummyClient
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity
  generateDummyUserFormData } = require '../../../../testhelper'


# making sure we have mongo connection before tests
beforeTests = -> before (done) ->

  checkBongoConnectivity done


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

        expectAccessDenied kodingGroup, 'kickMember', 'someAccountId', done


    describe 'when group slug is not koding', ->

      group        = {}
      groupSlug    = generateRandomString()
      adminClient  = {}
      adminAccount = {}

      # before running test cases creating a group
      before (done) ->

        options = { createGroup : yes, context : { group : groupSlug } }
        withConvertedUser options, (data) ->
          { group, client : adminClient, account : adminAccount } = data
          done()


      it 'should pass error if user tries kick own account', (done) ->

        # expecting not to be able to kick own account
        expectedError = 'You cannot kick yourself, try leaving the group!'
        group.kickMember adminClient, adminAccount._id, (err) ->
          expect(err?.message).to.be.equal expectedError
          done()


      it 'should be able to kick member if client has permission', (done) ->

        options = { context : { group : groupSlug } }
        withConvertedUser options, ({ client, account, userFormData }) ->

          queue = [

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
        username = 'someRandomNonExistingUsername'

        withDummyClient ({ client }) ->

          queue = [

            ->
              # fetching koding group
              JGroup.one { slug : 'koding' }, (err, group_) ->
                expect(err).to.not.exist
                group = group_
                queue.next()

            ->
              # expecting to not be able to fetch members data
              group.searchMembers client, username, {}, (err, members) ->
                expect(err?.message).to.be.equal 'Access denied'
                expect(members).to.not.exist
                queue.next()

            -> done()

          ]

          daisy queue


    describe 'if username is registered', ->

      it 'should be able to fetch by username for koding group slug', (done) ->

        withConvertedUser ({ client, userFormData }) ->
          group = {}

          queue = [

            ->
              # fetching group
              JGroup.one { slug : 'koding' }, (err, group_) ->
                expect(err).to.not.exist
                group = group_
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

        group       = {}
        groupSlug   = generateRandomString()
        adminClient = {}

        # before running test cases creating a group
        before (done) ->
          options = { createGroup : yes, context : { group : groupSlug } }
          withConvertedUser options, (data) ->
            { group, client : adminClient } = data
            done()

        it 'should not be able to fetch search result if not a member of group', (done) ->

          username = generateRandomUsername()

          withDummyClient ({ client }) ->
            # expecting not to be able to fetch member data
            group.searchMembers client, username, {}, (err, members) ->
              expect(err?.message).to.be.equal 'Access denied'
              done()


        it 'should be able to fetch member data after registering to group', (done) ->

          options = { context : { group : groupSlug } }
          withConvertedUser options, ({ client, account, userFormData }) ->

            queue = [

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

      # expecting to return true for any domain
      JGroup.one { slug : 'koding' }, (err, group) ->
        expect(err).to.not.exist
        expect(group.isInAllowedDomain 'someRandomDomain').to.be.ok
        done()


    it 'should return false if group does not have allowedDomains', (done) ->

      groupSlug = generateRandomString()

      groupData =
        slug           : groupSlug
        title          : generateRandomString()
        visibility     : 'visible'
        allowedDomains : []

      options = { createGroup : yes, context : { group : groupSlug }, groupData }
      withConvertedUser options, ({ client, account, group }) ->
        expect(group.isInAllowedDomain 'someRandomDomain').not.to.be.ok
        done()


    it 'should return true if group is in allowedDomains', (done) ->

      groupSlug = generateRandomString()

      groupData =
        slug           : groupSlug
        title          : generateRandomString()
        visibility     : 'visible'
        allowedDomains : ['gmail.com']

      allowedDomainEmail = generateRandomEmail groupData.allowedDomains[0]

      options = { createGroup : yes, context : { group : groupSlug }, groupData }
      withConvertedUser options, ({ client, account, group }) ->
        expect(group.isInAllowedDomain allowedDomainEmail).to.be.ok
        done()


  describe '#create()', ->

    describe 'when group data is valid', ->

      it 'should be able to create group', (done) ->

        group      = null
        groupSlug  = generateRandomString()
        groupTitle = generateRandomString()

        groupData =
          slug           : groupSlug
          title          : groupTitle
          visibility     : 'visible'
          allowedDomains : [ 'koding.com' ]

        withConvertedUser ({ client, account, userFormData }) ->

          queue = [

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
              expectRelation.toExist params, ->
                queue.next()

            ->
              # expecting account to be saved as a member
              params =
                $and : [
                  { as       : 'member' }
                  { sourceId : group._id }
                  { targetId : account._id }
                ]

              expectRelation.toExist params, ->
                queue.next()

            -> done()

          ]

          daisy queue


    describe 'when group data is not valid', ->

      it 'should pass error if slug is empty or set as koding', (done) ->

        groupData =
          slug       : ''
          title      : generateRandomString()
          visibility : 'visible'

        withConvertedUser ({ client, account }) ->

          queue = [

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

        groupSlug = generateRandomString()

        groupData =
          slug       : groupSlug
          title      : generateRandomString()
          visibility : 'visible'

        options = { createGroup : yes, context : { group : groupSlug }, groupData }
        withConvertedUser options, ({ client, account, group }) ->

          # expecting error using already claimed slug
          JGroup.create client, groupData, account, (err, data) ->
            expect(err?.message).to.be.equal "The slug #{groupSlug} is not available."
            done()


  describe 'fetchApiTokens$()', ->

    it 'should fail if user doesnt have permission', (done) ->

      groupSlug = generateRandomString()
      options = { createGroup : yes, context : { group : groupSlug } }
      withConvertedUser options, ({ client, group }) ->
        expectAccessDenied group, 'fetchApiTokens$', done


    it 'should be able to fetch api tokens with valid request', (done) ->

      groupSlug = generateRandomString()
      groupData = { isApiEnabled : yes }
      options = { createGroup : yes, context : { group : groupSlug }, groupData }
      withConvertedUser options, ({ client, account, group }) ->

        queue = []
        count = 5

        for i in [0...count]
          queue.push (next) ->
            JApiToken.create { account, group : groupSlug }, (err, apiToken) ->
              expect(err).to.not.exist
              expect(apiToken).to.exist
              next()

        queue.push (next) ->
          group.fetchApiTokens$ client, (err, apiTokens) ->
            expect(err).to.not.exist
            expect(apiTokens).to.be.an 'array'
            expect(apiTokens).to.have.length count
            expect(apiTokens[0].bongo_.constructorName).to.equal 'JApiToken'
            done()

        async.series queue


  describe 'setPlan()', ->

    describe 'when permissions are not valid', ->

      it 'should fail if user is not an admin', (done) ->

        options = { createGroup : yes }
        withConvertedUser options, ({ client, group }) ->
          expectAccessDenied group, 'setPlan', done


      it 'should fail if user an admin in a group but not in koding', (done) ->

        options = { createGroup: yes, role: 'admin' }

        withConvertedUser options, ({ client, group }) ->
          group.setPlan client, { plan: 'default' }, (err) ->
            expect(err).to.exist
            expect(err.message).to.be.equal 'Access denied'

            done()


    describe 'when permissions are ok', ->

      it 'should fail if user wants to set plan for koding group', (done) ->

        options = { role: 'admin' }

        withConvertedUser options, ({ client, group }) ->
          group.setPlan client, { plan: 'default' }, (err) ->
            expect(err).to.exist
            expect(err.message).to.be.equal 'Setting a plan on koding is not allowed'

            done()

      it 'should fail if plan is not supported', (done) ->

        withConvertedUser { createGroup: 'yes' }, ({ group }) ->

          withConvertedUser { role: 'admin' }, ({ client }) ->
            group.setPlan client, { plan: generateRandomString() }, (err) ->
              expect(err).to.exist

              done()

      testGroup = null

      it 'should allow to change if provided plan is valid', (done) ->

        withConvertedUser { createGroup: 'yes' }, ({ group }) ->

          testGroup = group

          withConvertedUser { role: 'admin' }, (data) ->
            _client = data.client

            group.setPlan _client, { plan: 'default' }, (err) ->
              expect(err).to.not.exist
              expect(group.getAt 'config.plan').to.be.equal 'default'

              done()

      it 'should reset plan if "noplan" is provided as plan', (done) ->

        withConvertedUser { role: 'admin' }, ({ client }) ->

          expect(testGroup.getAt 'config.plan').to.be.equal 'default'

          testGroup.setPlan client, { plan: 'noplan' }, (err) ->
            expect(err).to.not.exist
            expect(testGroup.getAt 'config.plan').to.not.exist

            done()


beforeTests()

runTests()
