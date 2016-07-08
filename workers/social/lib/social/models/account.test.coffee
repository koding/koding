{ async
  expect
  expectRelation
  withDummyClient
  withConvertedUser
  generateDummyClient
  generateRandomString
  checkBongoConnectivity } = require '../../../testhelper'

JUser            = require './user'
JGroup           = require './group'
JAccount         = require './account'
{ Relationship } = require 'jraphical'


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

        adminAccount.fetchAllParticipatedGroups$ adminClient, (err, groups) ->
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
              account.fetchAllParticipatedGroups$ client, (err, groups) ->
                expect(err).to.not.exist
                expect(groups).to.have.length.above(1)
                next()

            (next) ->
              account.leaveFromAllGroups client, (err) ->
                expect(err).to.not.exist
                next()

            (next) ->
              account.fetchAllParticipatedGroups$ client, (err, groups) ->
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


beforeTests()

runTests()
