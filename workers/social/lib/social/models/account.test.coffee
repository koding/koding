{ async
  expect
  expectRelation
  withDummyClient
  withConvertedUser
  generateDummyClient
  generateUserInfo
  createCustomClient
  generateRandomString
  generateRandomEmail
  checkBongoConnectivity } = require '../../../testhelper'

{ createUserAndMachine } = require '../../../testhelper/models/computeproviders/machinehelper'

{ generateMetaData } = require \
  '../../../testhelper/models/computeproviders/credentialhelper'

{ withConvertedUserAnd } = require  \
  '../../../testhelper/models/computeproviders/computeproviderhelper'

JUser            = require './user'
JGroup           = require './group'
JAccount         = require './account'
{ Relationship } = require 'jraphical'
JInvitation      = require './invitation'
JApiToken        = require './apitoken'
JComputeStack    = require './stack'
JMachine         = require './computeproviders/machine'
JStackTemplate   = require './computeproviders/stacktemplate'
JCredential      = require './computeproviders/credential'

{ generateStackTemplateData
  generateStackMachineData } = require \
  '../../../testhelper/models/computeproviders/stacktemplatehelper'



# making sure we have db connection before tests
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.user.account', ->

  describe '#modify()', ->

    it 'should pass error if fields contain invalid key', (done) ->

      withConvertedUser ({ client, account }) ->
        fields = { someInvalidField : 'someInvalidField' }
        account.modify client, fields, (err) ->
          expect(err?.message).to.be.equal 'Modify fields is not valid'
          done()


    it 'should update given fields correctly', (done) ->

      withConvertedUser ({ client, account }) ->

        fields =
          'profile.about'     : 'newAbout'
          'profile.lastName'  : 'newLastName'
          'profile.firstName' : 'newFirstName'

        # expecting account to be modified
        account.modify client, fields, (err, data) ->
          expect(err).to.not.exist

          # expecting account's values to be changed
          for key, value of fields
            expect(account.getAt key).to.be.equal value
          done()


  describe '#createSocialApiId()', ->

    describe 'when account type is unregistered', ->

      it 'should return -1', (done) ->

        withDummyClient ({ client, account }) ->
          # expecting unregistered account to return -1
          account.createSocialApiId (err, socialApiId) ->
            expect(err).to.not.exist
            expect(socialApiId).to.be.equal -1
            done()



    describe 'when account type is not unregistered', ->

      it 'should return socialApiId if socialApiId is already set', (done) ->

        withConvertedUser ({ client, account }) ->
          socialApiId = '12345'

          queue = [

            (next) ->
              # setting social api id
              account.update { $set : { socialApiId : socialApiId } }, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              # expecting createsocialApiId method to return accountId
              account.createSocialApiId (err, socialApiId_) ->
                expect(err).to.not.exist
                expect(socialApiId_).to.be.equal socialApiId
                next()

          ]

          async.series queue, done


      it 'should create social api id if account\'s socialApiId is not set', (done) ->

        withConvertedUser ({ client, account }) ->

          queue = [

            (next) ->
              # unsetting account's socialApiId
              account.socialApiId = null
              account.update { $unset : { 'socialApiId' : 1 } }, (err) ->
                expect(err).to.not.exist
                expect(account.getAt 'socialApiId').to.not.exist
                next()

            (next) ->
              # creating new social api id
              account.createSocialApiId (err, socialApiId_) ->
                expect(err).to.not.exist
                expect(socialApiId_).to.exist

                # expecting account's social api id to be set
                expect(account.getAt 'socialApiId').to.exist
                expect(account.socialApiId).to.exist
                next()

          ]

          async.series queue, done


  describe '#fetchMyPermissions()', ->

    describe 'when group does not exist', ->

      it 'should return error', (done) ->

        withDummyClient { group : 'someInvalidGroup' }, ({ client, account }) ->
          # expecting error when client's group does not exist
          account.fetchMyPermissions client, (err, permissions) ->
            expect(err?.message).to.be.equal 'group not found'
            done()


    describe 'when group exists', ->

      describe 'if account is valid', ->

        it 'should return client\'s permissions', (done) ->

          withDummyClient ({ client, account }) ->
            # expecting to be able to get permissions
            account.fetchMyPermissions client, (err, permissions) ->
              expect(err).to.not.exist
              expect(permissions).to.exist
              expect(permissions).to.be.an 'object'
              done()


      describe 'if group slug is not defined', ->

        it 'should set the slug as koding and return permissions', (done) ->

          withDummyClient ({ client, account }) ->
            # expecting to be able to get permissions
            account.fetchMyPermissions client, (err, permissions) ->
              expect(err).to.not.exist
              expect(permissions).to.exist
              expect(permissions).to.be.an 'object'
              done()

  describe '#destroy()', ->

    group  = {}
    group1 = {}
    group2 = {}

    adminClient  = {}

    email = generateRandomEmail()

    group2Slug = null

    client  = {}
    account = {}

    stackTemplate = null

    describe 'create groups as owner and admin', ->

      groupData1 =
        slug       : generateRandomString()
        title      : generateRandomString()
        visibility : 'visible'

      before (done) ->

        withConvertedUser { createGroup: true }, (data) ->
          { account, client, group } = data

          queue = [
            (next) ->
              # creating a new group as owner
              JGroup.create client, groupData1, account, (err, group_) ->
                expect(err).to.not.exist
                group1 = group_
                next()

            (next) ->
              # creeate new group and add account as an admin to this team
              withConvertedUser { createGroup: true }, (data) ->
                { group: group2 } = data
                group2Slug = group2.getAt 'slug'
                group2.addAdmin account, next

            (next) ->
              # create a session for AdminAccount to be able to create resources
              createCustomClient group2Slug, account, (err, client_) ->
                adminClient = client_
                expect(err).to.not.exist
                next()

            (next) ->
              # creating resources for group2 for adminAccount
              createResourcesQueue = [
                (next) ->

                  provider = 'aws'
                  options  =
                    meta     : generateMetaData provider
                    title    : 'someCredentialTitle'
                    provider : provider

                  JCredential.create adminClient, options, (err, credential) ->
                    expect(err).to.not.exist
                    expect(credential).to.exist
                    next()

                (next) ->
                  data = { machines: generateStackMachineData 1 }
                  stackTemplateData = generateStackTemplateData adminClient, data
                  JStackTemplate.create adminClient, stackTemplateData, (err, template) ->
                    expect(err).to.not.exist
                    expect(template).to.exist
                    stackTemplate = template
                    next()

                (next) ->
                  config = { verified: yes }
                  stackTemplate.update$ adminClient, { config }, (err) ->
                    expect(err).to.not.exist
                    next()

                (next) ->
                  stackTemplate.generateStack adminClient, {}, (err, res) ->
                    { stack, results: { machines } } = res
                    expect(err).to.not.exist
                    expect(machines).to.exist
                    expect(machines[0].err).to.not.exist
                    expect(machines[0].obj).to.exist
                    expect(stack).to.exist
                    next()

                (next) ->
                  JInvitation.create adminClient, { invitations: [{ email }] }, (err) ->
                    expect(err).to.not.exist
                    next()

                (next) ->
                  group2.modify adminClient, { isApiEnabled : yes }, (err) ->
                    expect(err).to.not.exist

                    JApiToken.create { account, group : group2Slug }, (err, apiToken) ->
                      expect(err).to.not.exist
                      expect(apiToken).to.exist
                      next()

                (next) ->
                  # create a user with machine and share it with Admin Client
                  userInfo = generateUserInfo()
                  createUserAndMachine userInfo, (err, data) ->
                    expect(err).to.not.exist
                    { machine } = data
                    params = { target : [ account.getAt 'profile.nickname' ], asUser : yes }
                    machine.shareWith params, (err) ->
                      expect(err).to.not.exist
                      next()
              ]

              async.series createResourcesQueue, next
          ]

          async.series queue, ->
            # number of groups that I am owner of
            account.fetchRelativeGroups (err, groups) ->

              expect(err).to.not.exist

              groups = groups.filter (group) -> group.slug isnt 'koding'
              expect(groups.length).to.be.equal 3

              groups = groups.filter (group) -> 'owner' in group.roles
              expect(groups.length).to.be.equal 2

              done()

      it 'should ensure that group2 have resources for adminAccount', (done) ->

        queue = [
          (next) ->
            JComputeStack.some { originId: account.getId(), group: group2Slug }, {}, (err, stacks) ->
              expect(err).to.not.exist
              expect(stacks.length).to.be.equal 1
              expect(group2Slug).to.be.equal stacks[0].group
              next()

          (next) ->
            JCredential.some$ adminClient, { originId: account.getId() }, (err, creds) ->
              expect(err).to.not.exist
              expect(creds.length).to.be.equal 1
              next()

          (next) ->
            JMachine.some { 'users.username': account.getAt('profile.nickname') }, {}, (err, machines) ->
              expect(err).to.not.exist
              expect(machines.length).to.be.equal 3
              next()

          (next) ->
            JApiToken.some { originId: account.getId() }, {}, (err, apiTokens) ->
              expect(err).to.not.exist
              expect(apiTokens.length).to.be.equal 1
              expect(group2Slug).to.be.equal apiTokens[0].group
              next()

          (next) ->
            JStackTemplate.some$ adminClient, { originId: account.getId() }, (err, stackTemplates) ->
              expect(err).to.not.exist
              expect(stackTemplates.length).to.be.equal 1
              expect(group2Slug).to.be.equal stackTemplates[0].group
              next()

          (next) ->
            JInvitation.some { inviterId: account.getId() }, {}, (err, invitations) ->
              expect(err).to.not.exist
              expect(invitations.length).to.be.equal 1
              expect(group2Slug).to.be.equal invitations[0].groupName
              next()
        ]

        async.series queue, done


      it 'should not allow to delete account when there more than one ownership', (done) ->

        account.destroy client, (err) ->
          expect(err).to.exist
          expect(err.message).to.be.equal 'You cannot delete your account when you have ownership in other team'
          done()


    describe 'delete team that I am owner of and account will clean all resources', ->

      before (done) ->

        queue = [
          (next) ->
            group1.destroy client, -> next()

          (next) ->
            account.destroy client, -> next()
        ]

        async.series queue, done


      it 'should delete resources of the adminAccount', (done) ->

        queue = [
          (next) ->
            JApiToken.some { originId: account.getId() }, {}, (err, apiTokens) ->
              expect(err).to.not.exist
              expect(apiTokens.length).to.be.equal 0
              next()

          (next) ->
            JCredential.some { originId: account.getId() }, {}, (err, creds) ->
              expect(err).to.not.exist
              expect(creds.length).to.be.equal 0
              next()

          (next) ->
            selector = { 'users.username' : account.getAt('profile.nickname') }
            JMachine.some selector, {}, (err, machines) ->
              expect(err).to.not.exist
              expect(machines.length).to.be.equal 0
              next()

          (next) ->
            JStackTemplate.some { originId: account.getId() }, {}, (err, stackTemplates) ->
              expect(err).to.not.exist
              expect(stackTemplates.length).to.be.equal 0
              next()

          (next) ->
            JInvitation.some { inviterId: account.getId() }, {}, (err, invitations) ->
              expect(err).to.not.exist
              expect(invitations.length).to.be.equal 0
              next()
        ]

        async.series queue, done


      it 'should ensure that account and group are deleted', (done) ->

        username = account.getAt 'profile.nickname'

        queue = [
          (next) ->
            JAccount.one { 'profile.nickname' : username }, (err, account_) ->
              expect(err).to.not.exist
              expect(account_).to.not.exist
              next()

          (next) ->
            JGroup.one { slug: group.slug }, (err, group_) ->
              expect(err).to.not.exist
              expect(group_).to.not.exist
              next()

          (next) ->
            JName = require './name'
            JName.one { name: username }, (err, name) ->
              expect(err).to.not.exist
              expect(name).to.not.exist
              next()

          (next) ->
            JUser.one { username }, (err, user) ->
              expect(err).to.not.exist
              expect(user).to.not.exist
              next()

          (next) ->
            JInvitation.one { inviterId: account.getId() }, (err, invitation) ->
              expect(err).to.not.exist
              expect(invitation).to.not.exist
              next()

          (next) ->
            JSession = require './session'
            JSession.one { username }, (err, session) ->
              expect(err).to.not.exist
              expect(session).to.not.exist
              next()

        ]

        async.series queue, done


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

        withConvertedUser ({ client, account }) ->
          adminClient  = client
          adminAccount = account

          # creating a new group
          JGroup.create adminClient, groupData, adminAccount, (err, group_) ->
            expect(err).to.not.exist
            group = group_
            done()


      it 'admin should have more than one group', (done) ->

        adminAccount.fetchAllParticipatedGroups (err, groups) ->
          expect(err).to.not.exist
          expect(groups).to.have.length.above(1)
          done()


      it 'standard user should be able to leave from all groups', (done) ->

        withConvertedUser ({ client, account, userFormData }) ->

          queue = [

            (next) ->
              JUser.addToGroup account, group.slug, userFormData.email, null, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              account.fetchAllParticipatedGroups (err, groups) ->
                expect(err).to.not.exist
                expect(groups).to.have.length.above(1)
                next()

            (next) ->
              account.leaveFromAllGroups client, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              account.fetchAllParticipatedGroups (err, groups) ->
                expect(err).to.not.exist
                expect(groups).to.have.length(1)
                next()

          ]

          async.series queue, done


  describe 'fetchOrCreateAppStorage()', ->

    describe 'when storage does not exist', ->

      it 'should create a new appStorage', (done) ->

        withConvertedUser ({ account }) ->
          appId      = generateRandomString()
          version    = '1.0.0'
          options    = { appId, version }

          # creating a new app storage
          account.fetchOrCreateAppStorage options, (err, appStorage) ->
            expect(err).to.not.exist
            expect(appStorage).to.be.an 'object'
            expect(appStorage.bongo_.constructorName).to.be.equal 'JCombinedAppStorage'
            expect(appStorage.accountId).to.be.deep.equal account._id
            expect(appStorage.bucket[appId]).to.be.an 'object'
            expect(appStorage.bucket[appId].data).to.be.an 'object'
            expect(appStorage.bucket[appId].data).to.be.empty
            done()


    describe 'when storage exists', ->

      it 'should return the existing appStorage', (done) ->

        withConvertedUser ({ account }) ->
          appId      = generateRandomString()
          version    = '1.0.0'
          options    = { appId, version }
          appStorage = null

          queue = [

            (next) ->
              # creating a new app storage
              account.fetchOrCreateAppStorage options, (err, storage) ->
                expect(err).to.not.exist
                appStorage = storage
                expect(appStorage).to.be.an 'object'
                expect(appStorage.bongo_.constructorName).to.be.equal 'JCombinedAppStorage'
                expect(appStorage.accountId).to.be.deep.equal account._id
                expect(appStorage.bucket[appId]).to.be.an 'object'
                expect(appStorage.bucket[appId].data).to.be.an 'object'
                expect(appStorage.bucket[appId].data).to.be.empty
                next()

            (next) ->
              # expecting previously created app storage to be fetched
              account.fetchOrCreateAppStorage options, (err, storage) ->
                expect(err).to.not.exist
                expect(storage.bongo_.constructorName).to.be.equal 'JCombinedAppStorage'
                expect(storage._id.toString()).to.be.equal appStorage._id.toString()
                expect(storage.accountId).to.be.deep.equal appStorage.accountId
                expect(storage.bucket[appId]).to.be.deep.equal appStorage.bucket[appId]
                next()

          ]

          async.series queue, done


    describe 'when another app storage request for same account', ->

      it 'should add a new property to storage object', (done) ->

        withConvertedUser ({ account }) ->

          appIds   = [generateRandomString(), generateRandomString()]
          versions = [generateRandomString(), generateRandomString()]

          queue = [

            (next) ->
              # creating a new app storage
              appId   = appIds[0]
              version = versions[0]
              options = { appId, version }

              account.fetchOrCreateAppStorage options, (err, storage) ->
                expect(err).to.not.exist
                appStorage = storage
                expect(appStorage).to.be.an 'object'
                expect(appStorage.bongo_.constructorName).to.be.equal 'JCombinedAppStorage'
                expect(appStorage.accountId).to.be.deep.equal account._id
                expect(appStorage.bucket[appId]).to.be.an 'object'
                expect(appStorage.bucket[appId].data).to.be.an 'object'
                expect(appStorage.bucket[appId].data).to.be.empty
                next()

            (next) ->
              appId   = appIds[1]
              version = versions[1]
              options = { appId, version }

              account.fetchOrCreateAppStorage options, (err, storage) ->
                expect(err).to.not.exist
                expect(storage).to.be.an 'object'
                expect(storage.bucket[appId].data).to.be.an 'object'
                expect(storage.bucket[appIds[0]]).to.be.an 'object'
                expect(storage.bucket[appIds[1]]).to.be.an 'object'
                next()

          ]

          async.series queue, done


  describe '#fetchAllParticipatedGroups()', ->

    account1 = {}
    account2 = {}
    group1   = {}
    group2   = {}

    checkFetchedGroups = (groups, expectedSlugs) ->

      expect(groups.length).to.be.equal expectedSlugs.length

      slugs = (group.slug for group in groups)
      for slug in expectedSlugs
        expect(slugs.indexOf slug).to.be.above -1


    before (done) ->

      queue = [
        (next) ->
          withConvertedUser { createGroup : yes }, ({ account, group }) ->
            account1 = account
            group1   = group
            next()
        (next) ->
          withConvertedUser { createGroup : yes }, ({ account, group }) ->
            account2 = account
            group2   = group
            group2.addAdmin account1, next
      ]

      async.series queue, (err) ->
        expect(err).to.not.exist
        expect(account1).to.exist
        expect(group1).to.exist
        expect(group2).to.exist
        done()

    it 'should return all user groups', (done) ->

      queue = [
        (next) ->
          account1.fetchAllParticipatedGroups (err, groups) ->
            expect(err).to.not.exist
            checkFetchedGroups groups, [ group1.slug, group2.slug, 'koding' ]
            next()
        (next) ->
          account2.fetchAllParticipatedGroups (err, groups) ->
            expect(err).to.not.exist
            checkFetchedGroups groups, [ group2.slug, 'koding' ]
            next()
      ]

      async.series queue, done


    it 'should return groups depending on user roles', (done) ->

      queue = [
        (next) ->
          options = { roles : [ 'owner' ] }
          account1.fetchAllParticipatedGroups options, (err, groups) ->
            expect(err).to.not.exist
            checkFetchedGroups groups, [ group1.slug ]
            next()
        (next) ->
          options = { roles : [ 'admin' ] }
          account1.fetchAllParticipatedGroups options, (err, groups) ->
            expect(err).to.not.exist
            checkFetchedGroups groups, [ group1.slug, group2.slug ]
            next()
        (next) ->
          options = { roles : [ 'moderator' ] }
          account1.fetchAllParticipatedGroups options, (err, groups) ->
            expect(err).to.not.exist
            checkFetchedGroups groups, []
            next()
      ]

      async.series queue, done


beforeTests()

runTests()
