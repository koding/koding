{ Relationship } = require 'jraphical'
JUser            = require '../user'
JGroup           = require './index'
JAccount         = require '../account'
JSession         = require '../session'
JApiToken        = require '../apitoken'
JInvitation      = require '../invitation'
JStackTemplate   = require '../computeproviders/stacktemplate'
JName            = require '../name'
JComputeStack    = require '../stack'
JMachine         = require '../computeproviders/machine'
JGroupData       = require './groupdata'
{ async
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

{ generateStackTemplateData } = require \
  '../../../../testhelper/models/computeproviders/stacktemplatehelper'


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

            (next) ->
              # making sure client is a member of the group before trying to kick
              group.searchMembers adminClient, userFormData.username, {}, (err, members) ->
                expect(err).to.not.exist
                expect(members.length).to.be.equal 1
                next()

            (next) ->
              # expecting session to exist before kicking member
              params =
                username  : account.profile.nickname
                groupName : client.context.group

              JSession.one params, (err, data) ->
                expect(err).to.not.exist
                expect(data).to.exist
                expect(data).to.be.an 'object'
                next()

            (next) ->
              # expecting no error from kick member request
              group.kickMember adminClient, account._id, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              # admin client search for kicked member within group member
              group.searchMembers adminClient, userFormData.username, {}, (err, members) ->
                expect(err).to.not.exist
                expect(members.length).to.be.equal 0
                next()

            (next) ->
              # expecting session to be deleted after kicking member
              params =
                username  : account.profile.nickname
                groupName : client.context.group

              JSession.one params, (err, data) ->
                expect(err).to.not.exist
                expect(data).to.not.exist
                next()

            (next) ->
              # we cannot add blocked user to group
              group.approveMember account, (err) ->
                expect(err).to.exist
                expect(err.message).to.be.equal 'This account is blocked'
                next()

            (next) ->
              # we should be able to unblock the member
              options =
                id: account.getId()
                removeUserFromTeam: no

              group.unblockMember adminClient, options, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              # unblocked member can be added again
              group.approveMember account, (err) ->
                expect(err).to.not.exist
                next()

          ]

          async.series queue, done


  describe '#transferOwnership()', ->

    describe 'create a team', ->

      group        = {}
      groupSlug    = generateRandomString()
      adminClient  = {}
      adminAccount = {}
      member1 = {}
      member2 = {}

      # before running test cases creating a group
      before (done) ->

        options = { createGroup : yes, context : { group : groupSlug } }
        withConvertedUser options, (data) ->
          { group, client : adminClient, account : adminAccount } = data
          group.fetchMyRoles adminClient, (err, roles) ->
            done()

      it 'should be able to add member to team', (done) ->

        options = { context : { group : groupSlug } }
        withConvertedUser options, (data) ->
          { account: member1 } = data
          done()

      it 'should be able to add member to team', (done) ->

        options = { context : { group : groupSlug } }
        withConvertedUser options, (data) ->
          { account: member2 } = data
          done()

      it 'should not be able to transferOwnership to kicked member', (done) ->

        accountId = member2._id

        queue = [
          (next) ->
            group.kickMember adminClient, accountId, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            group.transferOwnership { accountId, slug: groupSlug }, (err) ->
              expect(err.message).to.be.equal 'You cannot transfer ownership to blocked account'
              next()
        ]

        async.series queue, done

      it 'should throw error for not provided account', (done) ->

        group.transferOwnership {}, (err) ->
          expect(err.message).to.be.equal 'Account is not provided'
          done()

      it 'should not transfer if client is not the owner of the group', (done) ->

        group.transferOwnership { clientAccountId: member1.getId(), accountId: member1.getId() }, (err) ->
          expect(err.message).to.be.equal 'You must be the owner to perform this action!'
          done()

      it 'should not transfer the ownership to group owner', (done) ->

        group.transferOwnership { accountId: adminAccount.getId() }, (err) ->
          expect(err.message).to.be.equal 'You cannot transfer ownership to yourself, concentrate and try again!'
          done()

      it 'should be able to transfer the ownership to the member', (done) ->

        accountId = member1._id
        slug = group.slug
        queue = [

          (next) ->
            group.transferOwnership { accountId, slug }, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            group.fetchRolesByAccount adminAccount, (err, roles) ->
              expect(err).to.not.exist
              expect(false).to.be.equal 'owner' in roles
              next()

          (next) ->
            # member1 is new owner
            group.fetchRolesByAccount member1, (err, roles) ->
              expect(err).to.not.exist
              expect(true).to.be.equal 'owner' in roles
              next()

        ]

        async.series queue, done


  describe '#destroy()', ->

    describe 'create a team', ->
      group = {}
      client = {}
      account = {}

      groupId = null

      groupSlug = generateRandomString()

      email = generateRandomEmail()

      userFormData = {}
      stackTemplate = {}

      before (done) ->
        options = { createGroup : yes, context : { group : groupSlug } }
        withConvertedUser options, (data) ->
          { group, client, account, userFormData } = data
          groupId = group._id
          done()

      it 'should add resources, invitations, apiToken, groupData to team and add slack integration to admin account', (done) ->

        queue = [
          (next) ->
            JInvitation.create client, { invitations: [{ email }] }, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            group.modify client, { isApiEnabled : yes }, (err) ->
              expect(err).to.not.exist

              JApiToken.create { account, group : groupSlug }, (err, apiToken) ->
                expect(err).to.not.exist
                expect(apiToken).to.exist
                next()

          (next) ->
            group.modifyData client, { 'foo': 'bar' }, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            stackTemplateData = generateStackTemplateData client
            JStackTemplate.create client, stackTemplateData, (err, template) ->
              expect(err).to.not.exist
              expect(template).to.exist
              stackTemplate = template
              next()

          (next) ->
            config = { verified: yes }
            stackTemplate.update$ client, { config }, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            stackTemplate.generateStack client, {}, (err, res) ->
              { stack, results: { machines } } = res
              expect(err).to.not.exist
              expect(machines).to.exist
              expect(stack).to.exist
              next()

          (next) ->
            JForeignAuth = require '../foreignauth'
            foreignData =
              foreignId: 'test-foreignid'
              foreignAuthType: 'test'
              foreignAuth:
                test: 'test-foreignAuth'

            username = account.profile.nickname
            JForeignAuth.create { foreignData, group: groupSlug, username }, (err, foreignAuth) ->
              expect(err).to.not.exist
              expect(foreignAuth).to.exist
              next()

          (next) ->
            # add slack integration
            slackIntegration =
              slack:
                "#{groupSlug}":
                  token : 'slack-token-test'

            username = account.profile.nickname

            JUser.update { username }, { $set: { foreignAuth: slackIntegration } }, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            # make sure slack integration is attached to user
            JUser.one { "foreignAuth.slack.#{groupSlug}": { $exists: true } }, (err, user) ->
              expect(err).to.not.exist
              expect(user.data.foreignAuth.slack).to.exist
              next()

          (next) ->
            params =
              $and : [
                { as       : 'owner' }
                { sourceId : group._id }
                { targetId : account._id }
              ]

            # expecting relationship to be created
            expectRelation.toExist params, ->
              next()

        ]

        async.series queue, done


      describe 'delete team and ensure the data is deleted', ->

        before (done) ->
          group.destroy client, ->
            done()


        it 'should clear team data and resources', (done) ->

          queue = [
            (next) ->
              JApiToken.some { group : groupSlug }, {}, (err, apiTokens) ->
                expect(err).to.not.exist
                expect(apiTokens.length).to.be.equal 0
                next()

            (next) ->
              account.fetchMySessions client, {}, (err, sessions) ->
                expect(err).to.not.exist
                expect(sessions.length).to.be.equal 0
                next()

            (next) ->
              JName.one { name: groupSlug }, (err, name) ->
                expect(err).to.not.exist
                expect(name).to.not.exist
                next()

            (next) ->
              JGroupData.one { slug: groupSlug }, (err, data) ->
                expect(err).to.not.exist
                expect(data).to.not.exist
                next()

            (next) ->
              JComputeStack.some client, { group: groupSlug }, (err, stacks) ->
                expect(err).to.not.exist
                expect(stacks.length).to.be.equal 0
                next()

            (next) ->
              JStackTemplate.some client, { group: groupSlug }, (err, stackTemplates) ->
                expect(err).to.not.exist
                expect(stackTemplates.length).to.be.equal 0
                next()

            (next) ->
              JMachine.some client, {}, (err, machines) ->
                expect(err).to.not.exist
                expect(machines.length).to.be.equal 0
                next()

            (next) ->
              JForeignAuth = require '../foreignauth'
              JForeignAuth.one { group: groupSlug }, (err, foreignAuth) ->
                expect(err).to.not.exist
                expect(foreignAuth).to.not.exist
                next()

            (next) ->
              JUser.one { "foreignAuth.slack.#{groupSlug}": { $exists: true } }, (err, user) ->
                expect(err).to.not.exist
                expect(user).to.not.exist
                next()

            (next) ->
              { sessionToken } = client
              url = '/api/social/payment/subscription/delete'
              { deleteReq } = require '../socialapi/requests'
              deleteReq url, { sessionToken }, (err, body) ->
                expect(err.error).to.be.equal 'koding.BadRequest'
                expect(err.description).to.be.equal 'not found'
                next()

            (next) ->
              params =
                $and : [
                  { as       : 'owner' }
                  { sourceId : groupId }
                  { targetId : account._id }
                ]

              # expecting relationship to be created
              expectRelation.toNotExist params, next

            (next) ->
              JGroup.one { slug: groupSlug }, (err, group) ->
                expect(err).to.not.exist
                expect(group).to.not.exist
                next()

            (next) ->
              JSession.one { groupName: groupSlug }, (err, session) ->
                expect(err).to.not.exist
                expect(session).to.not.exist
                next()

          ]

          async.series queue, ->
            done()


  describe '#leave()', ->

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

      it 'should be able leave the group', (done) ->

        options = { context : { group : groupSlug } }
        withConvertedUser options, ({ client, account, userFormData }) ->

          queue = [
            (next) ->
              # expecting no error from kick member request
              group.leave client, {}, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              # admin client search for kicked member within group member
              group.searchMembers adminClient, userFormData.username, {}, (err, members) ->
                expect(err).to.not.exist
                expect(members.length).to.be.equal 0
                next()

            (next) ->
              # expecting session to be deleted after kicking member
              params =
                username  : account.profile.nickname
                groupName : client.context.group

              JSession.one params, (err, data) ->
                expect(err).to.not.exist
                expect(data).to.not.exist
                next()
          ]

          async.series queue, done


  describe '#searchMembers()', ->

    describe 'if username is unregistered', ->

      it 'should not fetch any data', (done) ->

        group    = {}
        username = 'someRandomNonExistingUsername'

        withDummyClient ({ client }) ->

          queue = [

            (next) ->
              # fetching koding group
              JGroup.one { slug : 'koding' }, (err, group_) ->
                expect(err).to.not.exist
                group = group_
                next()

            (next) ->
              # expecting to not be able to fetch members data
              group.searchMembers client, username, {}, (err, members) ->
                expect(err?.message).to.be.equal 'Access denied'
                expect(members).to.not.exist
                next()

          ]

          async.series queue, done


    describe 'if username is registered', ->

      it 'should be able to fetch by username for koding group slug', (done) ->

        withConvertedUser ({ client, userFormData }) ->
          group = {}

          queue = [

            (next) ->
              # fetching group
              JGroup.one { slug : 'koding' }, (err, group_) ->
                expect(err).to.not.exist
                group = group_
                next()

            (next) ->
              # expecting to find newly registered member
              group.searchMembers client, userFormData.username, {}, (err, members) ->
                expect(err).to.not.exist
                expect(members.length).to.be.equal 1
                expect(members[0].profile.nickname).to.be.equal userFormData.username
                next()

          ]

          async.series queue, done


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

              (next) ->
                # expecting new member client to be able fetch self data
                group.searchMembers client, userFormData.username, {}, (err, members) ->
                  expect(err).to.not.exist
                  expect(members[0].profile.nickname).to.be.equal userFormData.username
                  next()

              (next) ->
                # expecting admin to be able to fetch new member's data
                group.searchMembers adminClient, userFormData.username, {}, (err, members) ->
                  expect(err).to.not.exist
                  expect(members[0].profile.nickname).to.be.equal userFormData.username
                  next()

            ]

            async.series queue, done


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

    it 'should return true if allowedDomains contains *', (done) ->

      groupSlug = generateRandomString()

      groupData =
        slug           : groupSlug
        title          : generateRandomString()
        visibility     : 'visible'
        allowedDomains : ['*']

      allowedDomainEmail = generateRandomEmail 'example.com'

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

            (next) ->
              # expecting group to be created successfully
              JGroup.create client, groupData, account, (err, group_) ->
                expect(err)                  .to.not.exist
                group = group_
                expect(group.slug)           .to.be.equal groupSlug
                expect(group.title)          .to.be.equal groupTitle
                expect(group.visibility)     .to.be.equal groupData.visibility
                expect(group.allowedDomains) .to.include groupData.allowedDomains[0]
                next()

            (next) ->
              # expecting owner account and group relationship to be created
              params =
                $and : [
                  { as       : 'owner' }
                  { sourceId : group._id }
                  { targetId : account._id }
                ]

              # expecting relationship to be created
              expectRelation.toExist params, ->
                next()

            (next) ->
              # expecting account to be saved as a member
              params =
                $and : [
                  { as       : 'member' }
                  { sourceId : group._id }
                  { targetId : account._id }
                ]

              expectRelation.toExist params, ->
                next()

          ]

          async.series queue, done


    describe 'when group data is not valid', ->

      it 'should pass error if slug is empty or set as koding', (done) ->

        groupData =
          slug       : ''
          title      : generateRandomString()
          visibility : 'visible'

        withConvertedUser ({ client, account }) ->

          queue = [

            (next) ->
              # expecting error for 'koding' slug
              groupData.slug = 'koding'

              expectedError = 'The slug koding is not available.'
              JGroup.create client, groupData, account, (err, data) ->
                expect(err?.message).to.be.equal expectedError
                next()

            (next) ->
              # expecting validaton error when slug is empty
              groupData.slug = ''

              JGroup.create client, groupData, account, (err, data) ->
                expect(err).to.exist
                next()

          ]

          async.series queue, done


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


  describe 'setLimit()', ->

    describe 'when permissions are not valid', ->

      it 'should fail if user is not an admin', (done) ->

        options = { createGroup : yes }
        withConvertedUser options, ({ client, group }) ->
          expectAccessDenied group, 'setLimit', done


      it 'should fail if user an admin in a group but not in koding', (done) ->

        options = { createGroup: yes, role: 'admin' }

        withConvertedUser options, ({ client, group }) ->
          group.setLimit client, { limit: 'default' }, (err) ->
            expect(err).to.exist
            expect(err.message).to.be.equal 'Access denied'

            done()


    describe 'when permissions are ok', ->

      it 'should fail if user wants to set limit for koding group', (done) ->

        options = { role: 'admin' }

        withConvertedUser options, ({ client, group }) ->
          group.setLimit client, { limit: 'default' }, (err) ->
            expect(err).to.exist
            expect(err.message).to.be.equal 'Setting a limit on koding is not allowed'

            done()

      it 'should allow to update limit overrides if provided limit is valid', (done) ->

        withConvertedUser { createGroup: 'yes' }, ({ group }) ->

          withConvertedUser { role: 'admin' }, (data) ->
            _client = data.client

            overrides = { member: 5, validFor: 25 }
            group.setLimit _client, { overrides }, (err) ->
              expect(err).to.not.exist
              expect(group.getAt 'config.limitOverrides').to.be.equal overrides

              done()


  describe 'joinUser()', ->

    describe 'when unregistered invitee with valid data', ->

      # preparation
      email = generateRandomEmail()
      username = generateRandomString()
      password = generateRandomString()
      slug = generateRandomString()

      groupData =
        slug: slug
        title: generateRandomString()
        isApiEnabled: yes

      options =
        createGroup: yes
        context: { group: slug }
        groupData: groupData

      token = accountId = groupId = null

      # create a team and an invitation.
      before (done) ->
        withConvertedUser options, ({ client, group }) ->
          JInvitation.create client, { invitations: [{ email }] }, (err) ->
            expect(err).to.not.exist
            groupId = group._id
            done()

      it 'should have a valid invitation', (done) ->

        JInvitation.one { email }, (err, invitation) ->
          expect(err).to.not.exist
          expect(invitation).to.exist
          expect(invitation.code).to.exist
          expect(invitation.email).to.be.equal email
          expect(invitation.status).to.be.equal 'pending'
          expect(invitation.groupName).to.be.equal slug

          # get the token
          token = invitation.code
          done()

      it 'should actually join user using invitation token', (done) ->

        generateDummyClient { group: slug }, (err, client) ->
          expect(err).to.not.exist

          joinOptions = { email, username, password, slug, invitationToken: token }
          JGroup.joinUser client, joinOptions, (err, result) ->
            expect(err).to.not.exist
            expect(result.token).to.exist

            done()

      it 'should create a session for new user', (done) ->

        JSession.one { username }, (err, session) ->
          expect(err).to.not.exist
          expect(session).to.exist
          expect(session.username).to.be.equal username
          done()

      it 'should create an account for new user', (done) ->
        JAccount.one { 'profile.nickname': username }, (err, account) ->
          expect(err).to.not.exist
          expect(account).to.exist
          accountId = account._id
          done()


      it 'should create add user as member to the group', (done) ->

        params =
          $and : [
            { as       : 'member' }
            { sourceId : groupId }
            { targetId : accountId }
          ]

        Relationship.one params, (err, relationship) ->
          expect(err).to.not.exist
          expect(relationship).to.exist
          done()

    describe 'when registered invitee with valid data', ->

      # preparation
      slug = generateRandomString()

      groupData =
        slug: slug
        title: generateRandomString()
        isApiEnabled: yes

      options =
        createGroup: yes
        context: { group: slug }
        groupData: groupData

      email = username = password = token = accountId = groupId = null

      # first create 1 team (team x) and 1 user (user a)
      # second create another team (team y)
      # then create an invitation for (user a) in (team y)
      before (done) ->
        # (team x) and (user a)
        withConvertedUser { createGroup: yes }, ({ userFormData }) ->
          { email, username, password } = userFormData
          # (team y)
          withConvertedUser options, ({ client, group }) ->
            JInvitation.create client, { invitations: [{ email }] }, (err) ->
              expect(err).to.not.exist
              groupId = group._id
              done()

      it 'should have an account for already registered user', (done) ->
        JAccount.one { 'profile.nickname': username }, (err, account) ->
          expect(err).to.not.exist
          expect(account).to.exist
          accountId = account._id
          done()

      it 'should have a valid invitation', (done) ->

        JInvitation.one { email }, (err, invitation) ->
          expect(err).to.not.exist
          expect(invitation).to.exist
          expect(invitation.code).to.exist
          expect(invitation.email).to.be.equal email
          expect(invitation.status).to.be.equal 'pending'
          expect(invitation.groupName).to.be.equal slug

          # get the token
          token = invitation.code
          done()

      it 'should actually join user to given group', (done) ->

        generateDummyClient { group: slug }, (err, client) ->
          expect(err).to.not.exist

          joinOptions = { email, username, password, slug, token }
          JGroup.joinUser client, joinOptions, (err, result) ->
            expect(err).to.not.exist
            expect(result.token).to.exist

            done()

      it 'should create add user as member to the group via relationships', (done) ->

        params =
          $and : [
            { as       : 'member' }
            { sourceId : groupId }
            { targetId : accountId }
          ]

        Relationship.one params, (err, relationship) ->
          expect(err).to.not.exist
          expect(relationship).to.exist
          done()


    describe 'when an unregistered user with allowed domain', ->

      it 'should join the user to group', (done) ->
        groupData =
          slug: generateRandomString()
          title: generateRandomString()
          allowedDomains: ['foobar.com']

        options =
          createGroup: yes
          context: { group: groupData.slug }
          groupData: groupData

        joinOptions =
          username: generateRandomString 8
          password: generateRandomString()
          email: "#{generateRandomString 12}@foobar.com"
          slug: groupData.slug

        withConvertedUser options, ({ group }) ->
          generateDummyClient { group: group.slug }, (err, client) ->
            expect(err).to.not.exist
            JGroup.joinUser client, joinOptions, (err, result) ->
              expect(err).to.not.exist
              expect(result.token).to.exist
              done()

    describe 'when a registered koding user with allowed domain', ->

      it 'should join the user to group', (done) ->

        groupData =
          slug: generateRandomString()
          title: generateRandomString()
          allowedDomains: ['foobar.com']

        options =
          createGroup: yes
          context: { group: groupData.slug }
          groupData: groupData

        userFormData = generateDummyUserFormData()
        userFormData.email = "#{generateRandomString 12}@foobar.com"

        withConvertedUser { createGroup: yes, userFormData }, ->
          withConvertedUser options, ({ group }) ->
            generateDummyClient { group: group.slug }, (err, client) ->
              expect(err).to.not.exist
              joinOptions =
                username: userFormData.username
                password: userFormData.password
                email: userFormData.email
                slug: group.slug

              JGroup.joinUser client, joinOptions, (err, result) ->
                expect(err).to.not.exist
                expect(result.token).to.exist
                done()

    describe 'when user tries to join a group without an allowed email', ->

      it 'should not allow user to join', (done) ->

        groupData =
          slug: generateRandomString()
          title: generateRandomString()
          allowedDomains: ['foobar.com']

        options =
          createGroup: yes
          context: { group: groupData.slug }
          groupData: groupData

        userFormData = generateDummyUserFormData()
        userFormData.email = "#{generateRandomString 12}@notallowed.com"

        withConvertedUser { createGroup: yes, userFormData }, ->
          withConvertedUser options, ({ group }) ->
            generateDummyClient { group: group.slug }, (err, client) ->
              expect(err).to.not.exist
              joinOptions =
                username: userFormData.username
                password: userFormData.password
                email: userFormData.email
                slug: group.slug

              JGroup.joinUser client, joinOptions, (err, result) ->
                expect(err).to.exist
                expect(err.message).to.be.equal 'Your email domain is not in allowed domains for this group'
                done()


    describe 'when invitation token is invalid', ->

      # preparation
      email = generateRandomEmail()
      username = generateRandomString()
      password = generateRandomString()
      slug = generateRandomString()

      groupData =
        slug: slug
        title: generateRandomString()
        isApiEnabled: yes

      options =
        createGroup: yes
        context: { group: slug }
        groupData: groupData

      token = null

      # create a team and an invitation.
      before (done) ->
        withConvertedUser options, ({ client, group }) ->
          JInvitation.create client, { invitations: [{ email }] }, (err) ->
            expect(err).to.not.exist
            JInvitation.one { email }, (err, invitation) ->
              expect(err).to.not.exist
              expect(invitation.groupName).to.be.equal slug
              expect(invitation.code).to.exist
              done()

      it 'should not allow user to join', (done) ->

        generateDummyClient { group: slug }, (err, client) ->
          expect(err).to.not.exist

          joinOptions = { email, username, password, slug, invitationToken: 'invalid-token' }
          JGroup.joinUser client, joinOptions, (err, result) ->
            expect(err).to.exist
            expect(err.message).to.be.equal 'Invalid invitation code!'
            done()


    describe 'when there is wrong alreadyMember option', ->

      it 'should not allow user to join', (done) ->

        withConvertedUser { createGroup: yes }, ({ group }) ->
          generateDummyClient { group: group.slug }, (err, client) ->
            expect(err).to.not.exist
            JGroup.joinUser client, { alreadyMember: 'true', username: 'foo' }, (err) ->
              expect(err).to.exist
              expect(err.message).to.be.equal 'Unknown user name'
              done()


    describe 'when the group has public access to all domains', ->

      it 'should be able to create a user and join them to group', (done) ->

        groupData =
          slug: generateRandomString()
          title: generateRandomString()
          visibility: 'visible'
          isApiEnabled: yes
          allowedDomains : ['*']

        options =
          createGroup: yes
          context: { group: groupData.slug }
          groupData: groupData

        joinOptions =
          username: generateRandomString 8
          password: generateRandomString()
          email: "#{generateRandomString 12}@#{generateRandomString 6}.com"
          slug: groupData.slug

        withConvertedUser options, ({ account, group }) ->
          generateDummyClient { group: group.slug }, (err, client) ->
            expect(err).to.not.exist
            JGroup.joinUser client, joinOptions, (err, result) ->
              expect(err).to.not.exist
              expect(result.token).to.exist
              done()

      it 'should be able to join a registered koding user to group', (done) ->

        groupData =
          slug: generateRandomString()
          title: generateRandomString()
          visibility: 'visible'
          isApiEnabled: yes
          allowedDomains : ['*']

        options =
          createGroup: yes
          context: { group: groupData.slug }
          groupData: groupData

        # first create a user
        withConvertedUser { createGroup: 'yes' }, ({ userFormData }) ->
          # then create our api enabled group
          withConvertedUser options, ({ client, group }) ->
            joinOptions =
              username: userFormData.username
              password: userFormData.password
              email: userFormData.email
              slug: group.slug
            # then join the initially created user to our new api enabled group
            JGroup.joinUser client, joinOptions, (err, result) ->
              expect(err).to.not.exist
              expect(result.token).to.exist

              done()


beforeTests()

runTests()
