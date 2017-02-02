JCredential      = require './credential'
JCredentialData  = require './credentialdata'
CredentialStore  = require './credentialstore'
{ async
  expect
  expectRelation
  withDummyClient
  withConvertedUser
  expectAccessDenied
  generateRandomString
  checkBongoConnectivity } = require '../../../../testhelper'
{ addToRemoveList
  generateMetaData
  removeGeneratedCredentials
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


    it 'should be able to create credential when the data is valid', (done) ->

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

        options.meta.foobar = '  trim this white space   '

        queue = [

          (next) ->
            # expecting credential to be created
            JCredential.create client, options, (err, credential_) ->
              expect(err).to.not.exist
              credential = credential_

              addToRemoveList client, credential.identifier

              expect(credential.provider).to.be.equal provider
              expect(credential.title).to.be.equal title
              expect(credential.identifier).to.exist
              expect(credential.originId).to.be.equal originId
              next()

          (next) ->
            # expecting credential data to be created as well
            CredentialStore.fetch client, credential.identifier, (err, credentialData_) ->
              expect(err).to.not.exist
              credentialData = credentialData_
              expect(credentialData).to.exist
              expect(credentialData.meta).to.be.an 'object'
              expect(credentialData.meta).to.be.deep.equal options.meta
              expect(credentialData.meta.foobar).to.be.equal 'trim this white space'
              next()

          (next) ->
            # expecting credential and account relation to be created
            options =
              as         : 'owner'
              targetId   : credential._id
              sourceId   : account.getId()
              targetName : 'JCredential'
              sourceName : 'JAccount'

            expectRelation.toExist options, ->
              next()

        ]

        async.series queue, done


  describe '#fetchByIdentifier()', ->

    it 'should be able to fetch credential', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        JCredential.fetchByIdentifier client, credential.identifier, (err, credential_) ->
          expect(err).to.not.exist
          expect(credential_).to.exist
          expect(credential_._id).to.be.deep.equal credential._id
          done()


  describe '#one$()', ->

    it 'should fail to fetch credential if user doesnt have permission', (done) ->

      expectAccessDenied JCredential, 'one$', identifier = '', done


    it 'should be able to fetch credential', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        JCredential.one$ client, credential.identifier, (err, credential_) ->
          expect(err).to.not.exist
          expect(credential_).to.exist
          expect(credential_._id).to.be.deep.equal credential._id
          done()


  describe '#some$()', ->

    it 'should fail to fetch credentials if user doesnt have permission', (done) ->

      expectAccessDenied JCredential, 'some$', selector = {}, options = {}, done


    it 'should be able to fetch credentials', (done) ->

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

          (next) ->
            withConvertedUser ({ userFormData, account }) ->
              otherAccount = account
              options = { target : userFormData.username, user : yes, owner : yes }

              credential.shareWith ownerClient, options, (err) ->
                expect(err).to.not.exist
                next()

          (next) ->
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
              next()

        ]

        async.series queue, done


    it 'should be able to fetch users after sharing with a group', (done) ->

      withConvertedUserAndCredential ({ client, account, credential }) ->
        group = null

        queue = [

          (next) ->
            groupSlug   = generateRandomString()
            options     = { context : { group : groupSlug } }

            withConvertedUserAnd ['Group'], options, (data) ->
              { group } = data
              options   = { target : groupSlug, user : yes, owner : yes }

              credential.shareWith client, options, (err) ->
                expect(err).to.not.exist
                next()

          (next) ->
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
              next()

        ]

        async.series queue, done


  describe 'setPermissionFor()', ->

    describe 'should be able to set permission of target', ->

      client         = {}
      account        = {}
      credential     = {}
      anotherAccount = {}
      group          = {}

      before (done) ->

        async.series [

          (next) ->
            withConvertedUserAndCredential (data) ->
              { client, account, credential } = data
              next()

          (next) ->
            withConvertedUser { createGroup: yes }, (data) ->
              { account: anotherAccount, group } = data
              next()

        ], done


      it 'should set permission for given account', (done) ->

        options = { user: yes, owner: yes }

        credential.setPermissionFor anotherAccount, options, (err) ->
          expect(err).to.not.exist

          options =
            as         : 'owner'
            targetId   : credential._id
            sourceId   : anotherAccount._id
            targetName : 'JCredential'
            sourceName : 'JAccount'

          expectRelation.toExist options, (relationship) ->
            expect(relationship.sourceId).to.be.deep.equal anotherAccount._id
            done()

      it 'should set permission for given group with custom accessLevel', (done) ->

        options = { user: true, accessLevel: JCredential.ACCESSLEVEL.READ }

        credential.setPermissionFor group, options, (err) ->
          expect(err).to.not.exist
          expect(credential.getAt('accessLevel')).to.be.equal JCredential.ACCESSLEVEL.READ

          options =
            as         : 'user'
            targetId   : credential._id
            sourceId   : group._id
            targetName : 'JCredential'
            sourceName : 'JGroup'

          expectRelation.toExist options, (relationship) ->
            expect(relationship.sourceId).to.be.deep.equal group._id
            done()


  describe 'shareWith', ->

    it 'should fail to share if target does not exist', (done) ->

      withConvertedUserAndCredential ({ client, credential }) ->
        options = { user: yes, owner: yes, target: 'nonExistent' }
        credential.shareWith client, options, (err) ->
          expect(err?.message).to.be.equal 'Target not found.'
          done()

    describe 'should be able to share the credential with the target', ->

      group        = {}
      client       = {}
      credential   = {}
      adminClient  = {}
      adminAccount = {}

      before (done) ->

        async.series [
          # Create a group, account and a credential belongs to that user
          (next) ->
            options = { createGroup: yes }
            withConvertedUserAndCredential options, (data) ->
              { client, credential, group } = data
              next()

          # Create another account add to the group as admin
          (next) ->
            withConvertedUser { groupSlug: group.slug, role: 'admin' }, (data) ->
              { account: adminAccount, client: adminClient } = data
              next()
        ], done


      it 'should not list not shared credentials from admins perspective', (done) ->
        JCredential.some$ adminClient, {}, (err, creds) ->
          expect(err).to.not.exist
          expect(creds).to.have.length 0
          done()

      it 'should be able to share a regular users credential with group with read accessLevel', (done) ->
        options       =
          user        : true
          accessLevel : JCredential.ACCESSLEVEL.READ
          target      : group.slug

        credential.shareWith client, options, (err) ->
          expect(err).to.not.exist
          done()

      it 'should be able to list shared credentials from admins perspective', (done) ->
        JCredential.some$ adminClient, {}, (err, creds) ->
          expect(err).to.not.exist
          expect(creds).to.have.length 1
          done()

      it 'shoul fail to list credential for regular members of same group', (done) ->
        withConvertedUser { groupSlug: group.slug, role: 'member' }, (data) ->
          JCredential.some$ data.client, {}, (err, creds) ->
            expect(err).to.not.exist
            expect(creds).to.have.length 0
            done()

      it 'should be able to fetch shared credential content from admins perspective', (done) ->
        credential.fetchData$ adminClient, (err, data) ->
          expect(err).to.not.exist
          expect(data).to.exist
          done()

      it 'should allow owner to re-set accessLevel', (done) ->
        options       =
          user        : true
          accessLevel : JCredential.ACCESSLEVEL.PRIVATE
          target      : group.slug

        credential.shareWith client, options, (err) ->
          expect(err).to.not.exist
          done()

      it 'should fail to fetch shared credential content from admins perspective if accessLevel is not right', (done) ->
        credential.fetchData$ adminClient, (err, data) ->
          expectAccessDenied credential, 'fetchData$', {}, done

      it 'should allow one to one share between users', (done) ->
        options  =
          user   : true
          owner  : true
          target : adminAccount.profile.nickname

        credential.shareWith$ client, options, (err) ->
          expect(err).to.not.exist

          options =
            as         : 'owner'
            targetId   : credential._id
            sourceId   : adminAccount._id
            targetName : 'JCredential'
            sourceName : 'JAccount'

          expectRelation.toExist options, (relationship) ->
            expect(relationship.sourceId).to.be.deep.equal adminAccount._id
            done()


    describe 'shareWith$()', ->

      it 'should fail to share if user doesnt have permission', (done) ->

        withConvertedUserAndCredential ({ credential }) ->
          expectAccessDenied credential, 'shareWith$', {}, done


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

    testFetchDataFailure = (method, args, done) ->
      withConvertedUserAndCredential ({ client, credential }) ->

        args  = [client].concat args ? []
        queue = [

          (next) ->
            credential[method] args..., (err, credData) ->
              CredentialStore.remove client, credData.identifier, (err) ->
                expect(err).to.not.exist
                next()

          (next) ->
            credential[method] args..., (err, data) ->
              expect(err?.message).to.be.equal 'No data found'
              next()

        ]

        async.series queue, done


    testFetchDataSuccess = (method, args, done) ->

      withConvertedUserAndCredential ({ client, credential }) ->

        args = [client].concat args ? []

        checkCredData = (err, credData) ->
          expect(err).to.not.exist
          expect(credData).to.be.an 'object'
          expect(credData.identifier).to.be.equal credential.identifier
          done()

        credential[method] args..., checkCredData


    describe 'fetchData()', ->

      it 'should fail if there is no data', (done) ->

        testFetchDataFailure 'fetchData', {}, done


      it 'should be able to fetch credential data', (done) ->

        testFetchDataSuccess 'fetchData', {}, done


    describe 'fetchData$()', ->

      it 'should fail to fetch data if user doesnt have the permission', (done) ->

        withConvertedUserAndCredential ({ credential }) ->
          expectAccessDenied credential, 'fetchData$', done


      it 'should fail if there is no data', (done) ->

        testFetchDataFailure 'fetchData$', null, done


      it 'should be able to fetch credential data', (done) ->

        testFetchDataSuccess 'fetchData$', null, done


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

      withConvertedUserAndCredential { provider : 'custom' }, ({ client, credential }) ->

        queue = [

          (next) ->
            options =
              title : 'newTitle'
              meta  : { data : 'newMeta' }

            credential.update$ client, options, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            JCredential.one { _id : credential._id }, (err, credential_) ->
              expect(err).to.not.exist
              expect(credential_.title).to.be.equal 'newTitle'
              expect(credential.fields).to.be.deep.equal [ 'data' ]
              next()

          (next) ->
            CredentialStore.fetch client, credential.identifier, (err, credData) ->
              expect(err).to.not.exist
              expect(credData.meta).to.be.deep.equal { data : 'newMeta' }
              next()

        ]

        async.series queue, done


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


afterTests = -> after removeGeneratedCredentials

beforeTests()

runTests()

afterTests()
