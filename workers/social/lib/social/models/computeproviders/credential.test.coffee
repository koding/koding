JCredential      = require './credential'
JCredentialData  = require './credentialdata'
{ daisy
  expect
  expectRelation
  withDummyClient
  withConvertedUser
  expectAccessDenied
  generateRandomString
  checkBongoConnectivity } = require '../../../../testhelper'
{ generateMetaData
  withConvertedUserAndCredential } = require \
  '../../../../testhelper/models/computeproviders/credentialhelper'
{ withConvertedUserAnd } = require \
  '../../../../testhelper/models/computeproviders/computeproviderhelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.models.computeproviders.credential', ->

  describe '#getName()', ->

    it 'should return name of the JCredential class', ->

      expect(JCredential.getName()).to.be.equal 'JCredential'


  describe '#create()', ->

    it 'should fail if user doesnt have the permission to create', (done) ->

      expectAccessDenied JCredential, 'create', data = {}, done


    it 'should fail to create credential if provider is not supported', (done) ->

      withConvertedUser ({ client }) ->
        JCredential.create client, { provider : 'invalid' }, (err) ->
          expect(err?.message).to.be.equal 'Provider is not supported'
          done()


    it 'should be able to ocreate credential when the data is valid', (done) ->

      withConvertedUser ({ client, account }) ->

        title          = 'someCredentialTitle'
        provider       = 'aws'
        originId       = account.getId()
        credential     = null
        credentialData = null

        options =
          meta     : generateMetaData provider
          title    : title
          provider : provider

        queue = [

          ->
            # expecting credential to be created
            JCredential.create client, options, (err, credential_) ->
              expect(err).to.not.exist
              credential = credential_
              expect(credential.provider).to.be.equal provider
              expect(credential.title).to.be.equal title
              expect(credential.identifier).to.exist
              expect(credential.originId).to.be.equal originId
              queue.next()

          ->
            # expecting credential data to be created as well
            JCredentialData.one { originId }, (err, credentialData_) ->
              expect(err).to.not.exist
              credentialData = credentialData_
              expect(credentialData).to.exist
              expect(credentialData.meta).to.be.an 'object'
              expect(credentialData.meta).to.be.deep.equal options.meta
              queue.next()

          ->
            # expecting credential and account relation to be created
            options =
              as         : 'owner'
              targetId   : credential._id
              sourceId   : account.getId()
              targetName : 'JCredential'
              sourceName : 'JAccount'

            expectRelation.toExist options, ->
              queue.next()

          ->
            # expecting credential and credential data relation to be created
            options =
              as         : 'data'
              targetId   : credentialData._id
              sourceId   : credential._id
              targetName : 'JCredentialData'
              sourceName : 'JCredential'

            expectRelation.toExist options, ->
              queue.next()

          -> done()

        ]

        daisy queue


  describe '#fetchByIdentifier()', ->

    it 'should be able to fetch credential', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        JCredential.fetchByIdentifier client, credential.identifier, (err, credential_) ->
          expect(err).to.not.exist
          expect(credential_).to.exist
          expect(credential_._id).to.be.deep.equal credential._id
          done()


  describe '#one$()', ->

    it 'should fail to fetch credential data if user doesnt have permission', (done) ->

      expectAccessDenied JCredential, 'one$', identifier = '', done


    it 'should be able to fetch credential data', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        JCredential.one$ client, credential.identifier, (err, credential_) ->
          expect(err).to.not.exist
          expect(credential_).to.exist
          expect(credential_._id).to.be.deep.equal credential._id
          done()


  describe '#some$()', ->

    it 'should fail to fetch credential data if user doesnt have permission', (done) ->

      expectAccessDenied JCredential, 'some$', selector = {}, options = {}, done


    it 'should be able to fetch credential data', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        selector = { _id : credential._id }
        options  = {}
        JCredential.some$ client, selector, options, (err, credentials) ->
          expect(err).to.not.exist
          expect(credentials).to.be.an 'array'
          expect(credentials).to.have.length 1
          done()


  describe 'fetchUsers()', ->

    it 'should fail to fetch users if user doesnt have permission', (done) ->

      withConvertedUserAndCredential ({ credential }) ->
        expectAccessDenied credential, 'fetchUsers', done


    it 'should be able to fetch users with valid request', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        credential.fetchUsers client, (err, users) ->
          expect(err).to.not.exist
          expect(users).to.be.an 'array'
          expect(users).to.have.length.above 0
          done()


    it 'should be able to fetch users after sharing with a user', (done) ->

      withConvertedUserAndCredential ({ client, account, credential }) ->
        ownerClient  = client
        ownerAccount = account
        otherAccount = null

        queue = [

          ->
            withConvertedUser ({ userFormData, account }) ->
              otherAccount = account
              options = { target : userFormData.username, user : yes, owner : yes }

              credential.shareWith ownerClient, options, (err) ->
                expect(err).to.not.exist
                queue.next()

          ->
            credential.fetchUsers ownerClient, (err, users) ->
              expect(err).to.not.exist
              expect(users).to.be.an 'array'
              expect(users).to.have.length 2
              expect(users[0]).to.be.an 'object'
              expect(users[0].constructorName).to.be.equal 'JAccount'
              expect(users[0]._id.toString()).to.be.equal ownerAccount._id.toString()
              expect(users[1]).to.be.an 'object'
              expect(users[1].constructorName).to.be.equal 'JAccount'
              expect(users[1]._id.toString()).to.be.equal otherAccount._id.toString()
              queue.next()

          -> done()

        ]

        daisy queue


    it 'should be able to fetch users after sharing with a group', (done) ->

      withConvertedUserAndCredential ({ client, account, credential }) ->
        group = null

        queue = [

          ->
            groupSlug   = generateRandomString()
            options     = { context : { group : groupSlug } }

            withConvertedUserAnd ['Group'], options, (data) ->
              { group } = data
              options   = { target : groupSlug, user : yes, owner : yes }

              credential.shareWith client, options, (err) ->
                expect(err).to.not.exist
                queue.next()

          ->
            credential.fetchUsers client, (err, users) ->
              expect(err).to.not.exist
              expect(users).to.be.an 'array'
              expect(users).to.have.length 2
              expect(users[0]).to.be.an 'object'
              expect(users[0].constructorName).to.be.equal 'JAccount'
              expect(users[0]._id.toString()).to.be.equal account._id.toString()
              expect(users[1]).to.be.an 'object'
              expect(users[1].constructorName).to.be.equal 'JGroup'
              expect(users[1]._id.toString()).to.be.equal group._id.toString()
              queue.next()

          -> done()

        ]

        daisy queue


  describe 'setPermissionFor()', ->

    it 'should be able to set permission of target', (done) ->

      client         = {}
      account        = {}
      credential     = {}
      anotherAccount = {}

      queue = [

        ->
          withConvertedUserAndCredential (data) ->
            { client, account, credential } = data
            queue.next()

        ->
          withConvertedUser (data) ->
            { account : anotherAccount } = data
            queue.next()

        ->
          options = { user : true, owner : true }
          credential.setPermissionFor anotherAccount, options, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          options =
            as         : 'owner'
            targetId   : credential._id
            sourceId   : anotherAccount._id
            targetName : 'JCredential'
            sourceName : 'JAccount'

          expectRelation.toExist options, (relationship) ->
            expect(relationship.sourceId).to.be.deep.equal anotherAccount._id
            queue.next()

        -> done()

      ]

      daisy queue


  describe 'shareWith', ->

    testShareWith = (method, done) ->
      client         = {}
      account        = {}
      credential     = {}
      anotherAccount = {}

      queue = [

        ->
          withConvertedUserAndCredential (data) ->
            { client, account, credential } = data
            queue.next()

        ->
          withConvertedUser (data) ->
            { account : anotherAccount } = data
            queue.next()

        ->
          options =
            user   : true
            owner  : true
            target : anotherAccount.profile.nickname

          credential[method] client, options, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          options =
            as         : 'owner'
            targetId   : credential._id
            sourceId   : anotherAccount._id
            targetName : 'JCredential'
            sourceName : 'JAccount'

          expectRelation.toExist options, (relationship) ->
            expect(relationship.sourceId).to.be.deep.equal anotherAccount._id
            queue.next()

        -> done()

      ]

      daisy queue


    describe 'shareWith()', ->

      it 'should fail to share if target does not exist', (done) ->

        withConvertedUserAndCredential ({ client, credential }) ->
          options = { user : true, owner : true, target : 'nonExistent' }
          credential.shareWith client, options, (err) ->
            expect(err?.message).to.be.equal 'Target not found.'
            done()


      it 'should be able to share the credential with the target', (done) ->

        testShareWith 'shareWith', done


    describe 'shareWith$()', ->

      it 'should fail to share if user doesnt have permission', (done) ->

        withConvertedUserAndCredential ({ credential }) ->
          expectAccessDenied credential, 'shareWith$', {}, done


      it 'should be able to share the credential with the target', (done) ->

        testShareWith 'shareWith$', done


  describe 'delete()', ->

    it 'should fail to delete if user doesnt have permission', (done) ->

      withConvertedUserAndCredential ({ credential }) ->
        expectAccessDenied credential, 'delete', done


    it 'should be able to delete the credential', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        credential.delete client, (err) ->
          expect(err).to.not.exist

          JCredential.one { _id : credential._id }, (err, credential) ->
            expect(err).to.not.exist
            expect(credential).to.not.exist
            done()


  describe 'fetchData', ->

    testFetchDataFailure = (method, done) ->
      withConvertedUserAndCredential ({ client, credential }) ->

        # adding client to args array, if method is for remote api
        # a client argument will be passed before callback
        args  = [client]  if method.slice(-1) is '$'
        args ?= []

        queue = [

          ->
            credential[method] args..., (err, credData) ->
              credData.remove (err) ->
                expect(err).to.not.exist
                queue.next()

          ->
            credential[method] args..., (err, data) ->
              expect(err?.message).to.be.equal 'No data found'
              queue.next()

          -> done()

        ]

        daisy queue


    testFetchDataSuccess = (method, done) ->
      withConvertedUserAndCredential ({ client, credential }) ->

        checkCredData = (err, credData) ->
          expect(err).to.not.exist
          expect(credData).to.be.an 'object'
          expect(credData.identifier).to.be.equal credential.identifier
          done()

        if   method.slice(-1) is '$'
        then credential[method] client, checkCredData
        else credential[method] checkCredData


    describe 'fetchData()', ->

      it 'should fail if there is no data', (done) ->

        testFetchDataFailure 'fetchData', done


      it 'should be able to fetch credential data', (done) ->

        testFetchDataSuccess 'fetchData', done


    describe 'fetchData$()', ->

      it 'should fail to fetch data if user doesnt have the permission', (done) ->

        withConvertedUserAndCredential ({ credential }) ->
          expectAccessDenied credential, 'fetchData$', done


      it 'should fail if there is no data', (done) ->

        testFetchDataFailure 'fetchData$', done


      it 'should be able to fetch credential data', (done) ->

        testFetchDataSuccess 'fetchData$', done


  describe 'update$', ->

    it 'should fail to update credential if user doesnt have the permission', (done) ->

      withConvertedUserAndCredential ({ credential }) ->
        expectAccessDenied credential, 'fetchData$', {}, done


    it 'should fail to update if title or meta is not set', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        credential.update$ client, { title : null }, (err) ->
          expect(err?.message).to.be.equal 'Nothing to update'
          done()


    it 'should be able to update credential', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->

        queue = [

          ->
            options =
              title : 'newTitle'
              meta  : { data : 'newMeta' }

            credential.update$ client, options, (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            JCredential.one { _id : credential._id }, (err, credential_) ->
              expect(err).to.not.exist
              expect(credential_.title).to.be.equal 'newTitle'
              queue.next()

          ->
            options = { identifier : credential.identifier }
            JCredentialData.one options, (err, credData) ->
              expect(err).to.not.exist
              expect(credData.meta).to.be.deep.equal { data : 'newMeta' }
              queue.next()

          -> done()

        ]

        daisy queue


  describe 'isBootstrapped()', ->

    it 'should fail to check if user doesnt have the permission', (done) ->

      withConvertedUserAndCredential ({ credential }) ->
        expectAccessDenied credential, 'isBootstrapped', done


    it 'should be able to check if credential is bootstrapped', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        credential.isBootstrapped client, (err, result) ->
          expect(err).to.not.exist
          expect(result).to.be.a 'boolean'
          done()


beforeTests()

runTests()

