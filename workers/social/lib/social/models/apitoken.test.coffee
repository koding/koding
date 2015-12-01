{ daisy
  expect
  withConvertedUser
  expectAccessDenied
  generateRandomString
  checkBongoConnectivity } = require '../../../testhelper'

JApiToken = require './apitoken'

# making sure we have db connection before tests
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'workers.social.apitoken', ->

  describe '#create()', ->

    it 'should fail to create api token when options is not valid', (done) ->

      queue = []

      invalidData = [
        { account : null, group   : '' }
        { account : {}  , group   : '' }
        { account : null  , group : generateRandomString() }
      ]

      invalidData.forEach (data) ->
        queue.push ->
          JApiToken.create data, (err, token) ->
            expect(err?.message).to.be.equal 'account and group slug must be set!'
            expect(token).to.not.exist
            queue.next()

      queue.push -> done()

      daisy queue


    it 'should fail to create api token when group or account is non-existent', (done) ->

      group = generateRandomString()
      options   = { context : { group }, createGroup : yes }

      withConvertedUser options, ({ client, account }) ->

        queue = [

          ->
            data = { group, account : {} }
            JApiToken.create data, (err, token) ->
              expect(err?.message).to.be.equal 'account is not an instance of Jaccount!'
              expect(token).to.not.exist
              queue.next()

          ->
            data = { group : generateRandomString(), account }
            JApiToken.create data, (err, token) ->
              expect(err?.message).to.be.equal 'group not found!'
              expect(token).to.not.exist
              queue.next()

          -> done()

        ]

        daisy queue


    it 'should fail if isApiTokenEnabled field is not true for the group', (done) ->

      group         = generateRandomString()
      groupData     = {}
      options       = { context : { group }, createGroup : yes, groupData }
      expectedError = 'api token usage is not enabled for this group'

      withConvertedUser options, ({ client, account }) ->

        data = { group, account }
        JApiToken.create data, (err, token) ->
          expect(err?.message).to.be.equal expectedError
          expect(token).to.not.exist
          done()


    it 'should be able to create api token with valid request', (done) ->

      group   = generateRandomString()
      options = { context : { group }, createGroup : yes }

      withConvertedUser options, ({ client, account }) ->

        data = { group, account }
        JApiToken.create data, (err, token) ->
          expect(err).to.not.exist
          expect(token.code).to.be.a 'string'
          expect(token.createdAt).to.exist
          expect(token.modifiedAt).to.exist
          expect(token.group).to.equal group
          expect(token.originId).to.deep.equal account._id
          done()


  describe '#create$()', ->

    it 'should return access denied if user is not an admin', (done) ->

      expectAccessDenied JApiToken, 'create$', {}, done


    it 'should be able to create with valid request', (done) ->

      group   = generateRandomString()
      options = { context : { group }, createGroup : yes }

      withConvertedUser options, ({ client, account }) ->

        JApiToken.create$ client, (err, token) ->
          expect(err).to.not.exist
          expect(token.code).to.be.a 'string'
          expect(token.createdAt).to.exist
          expect(token.modifiedAt).to.exist
          expect(token.group).to.equal group
          expect(token.originId).to.deep.equal account._id
          done()


  describe 'remove$()', ->

    it 'should return access denied if user is not an admin', (done) ->

      group   = generateRandomString()
      options = { context : { group }, createGroup : yes }
      withConvertedUser options, ({ client }) ->
        JApiToken.create$ client, (err, token) ->
          expectAccessDenied token, 'remove$', done


    it 'should be able to delete token with valid request', (done) ->

      group   = generateRandomString()
      options = { context : { group }, createGroup : yes }

      withConvertedUser options, ({ client }) ->

        JApiToken.create$ client, (err, token) ->
          expect(err).to.not.exist

          token.remove$ client, (err) ->
            expect(err).to.not.exist
            done()


beforeTests()

runTests()

