{ daisy
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
JAppStorage      = require './appstorage'
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

            ->
              # setting social api id
              account.update { $set : { socialApiId : socialApiId } }, (err) ->
                expect(err).to.not.exist
                queue.next()

            ->
              # expecting createsocialApiId method to return accountId
              account.createSocialApiId (err, socialApiId_) ->
                expect(err).to.not.exist
                expect(socialApiId_).to.be.equal socialApiId
                queue.next()

            -> done()

          ]

          daisy queue


      it 'should create social api id if account\'s socialApiId is not set', (done) ->

        withConvertedUser ({ client, account }) ->

          queue = [

            ->
              # unsetting account's socialApiId
              account.socialApiId = null
              account.update { $unset : { 'socialApiId' : 1 } }, (err) ->
                expect(err).to.not.exist
                expect(account.getAt 'socialApiId').to.not.exist
                queue.next()

            ->
              # creating new social api id
              account.createSocialApiId (err, socialApiId_) ->
                expect(err).to.not.exist
                expect(socialApiId_).to.exist

                # expecting account's social api id to be set
                expect(account.getAt 'socialApiId').to.exist
                expect(account.socialApiId).to.exist
                queue.next()

            -> done()

          ]

          daisy queue


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

        adminAccount.fetchAllParticipatedGroups adminClient, (err, groups) ->
          expect(err).to.not.exist
          expect(groups).to.have.length.above(1)
          done()


      it 'standard user should be able to leave from all groups', (done) ->

        withConvertedUser ({ client, account, userFormData }) ->

          queue = [

            ->
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
            expect(appStorage.storage[appId]).to.be.an 'object'
            expect(appStorage.storage[appId]['data']).to.be.an 'object'
            expect(appStorage.storage[appId]['data']).to.be.empty
            done()


    describe 'when storage exists', ->

      it 'should return the existing appStorage', (done) ->

        withConvertedUser ({ account }) ->
          appId      = generateRandomString()
          version    = '1.0.0'
          options    = { appId, version }
          appStorage = null

          queue = [

            ->
              # creating a new app storage
              account.fetchOrCreateAppStorage options, (err, storage) ->
                expect(err).to.not.exist
                appStorage = storage
                expect(appStorage).to.be.an 'object'
                expect(appStorage.bongo_.constructorName).to.be.equal 'JCombinedAppStorage'
                expect(appStorage.accountId).to.be.deep.equal account._id
                expect(appStorage.storage[appId]).to.be.an 'object'
                expect(appStorage.storage[appId]['data']).to.be.an 'object'
                expect(appStorage.storage[appId]['data']).to.be.empty
                queue.next()

            ->
              # expecting previously created app storage to be fetched
              account.fetchOrCreateAppStorage options, (err, storage) ->
                expect(err).to.not.exist
                expect(storage.bongo_.constructorName).to.be.equal 'JCombinedAppStorage'
                expect(storage._id.toString()).to.be.equal appStorage._id.toString()
                expect(storage.accountId).to.be.deep.equal appStorage.accountId
                expect(storage.storage[appId]).to.be.deep.equal appStorage.storage[appId]
                queue.next()

            -> done()

          ]

          daisy queue


  describe 'migrateOldAppStorageIfExists()', ->

    createOldAppStorageDocument = (data, callback) ->
      { account, appId, version, bucket } = data
      bucket ?= {}

      storage = new JAppStorage { appId, version, bucket }
      storage._shouldPrune = no
      storage.save (err) ->
        return callback err  if err

        relationshipOptions =
          targetId    : storage.getId()
          targetName  : 'JAppStorage'
          sourceId    : account.getId()
          sourceName  : 'JAccount'
          as          : 'appStorage'
          data        : { appId, version }

        rel = new Relationship relationshipOptions
        rel.save (err) ->
          callback err, { storage, relationshipOptions }


    it 'should return null if storage doesnt exist', (done) ->

      withConvertedUser ({ account }) ->

        account.migrateOldAppStorageIfExists {}, (err, storage) ->
          expect(err).to.not.exist
          expect(storage).to.not.exist
          done()


    it 'should migrate old storage if there is one', (done) ->

      withConvertedUser ({ account }) ->

        version             = generateRandomString()
        appId               = generateRandomString()
        bucket              = {}
        oldStorage          = {}
        relationshipOptions = {}

        queue = [

          ->
            # creating an old app storage document
            bucket =
              someString  : generateRandomString()
              someData    :
                moreData  : { data : {} }
              anotherData :
                someArray : [1,2,3]

            options = { account, appId, version, bucket }
            createOldAppStorageDocument options, (err, data) ->
              expect(err).to.not.exist
              { storage : oldStorage, relationshipOptions } = data
              expect(oldStorage.bongo_.constructorName).to.be.equal 'JAppStorage'
              queue.next()

          ->
            # expecting old app storage document to be migrated
            options = { appId, version }
            account.migrateOldAppStorageIfExists options, (err, newStorage) ->
              expect(err).to.not.exist
              console.log newStorage
              expect(newStorage).to.be.an 'object'
              expect(newStorage.bongo_.constructorName).to.be.equal 'JCombinedAppStorage'
              expect(newStorage.accountId).to.be.deep.equal account._id
              expect(newStorage.storage[appId].data).to.be.deep.equal bucket
              expect(newStorage.storage.bucket).to.not.exist
              expect(newStorage.storage.version).to.not.exist
              queue.next()

          ->
            # expecting old storage document to be deleted
            options = { appId, version }
            JAppStorage.one options, (err, oldStorage) ->
              expect(err).to.not.exist
              expect(oldStorage).to.not.exist
              queue.next()

          ->
            # expecting relationship to be deleted
            expectRelation.toNotExist relationshipOptions, (err, data) ->
              expect(err).to.not.exist
              expect(data).to.not.exist
              queue.next()

          -> done()

        ]

        daisy queue



beforeTests()

runTests()


