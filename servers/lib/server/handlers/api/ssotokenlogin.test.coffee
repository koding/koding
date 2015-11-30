{ daisy
  expect
  request
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity }             = require '../../../../testhelper'
{ withConvertedUser }                  = require '../../../../../workers/social/testhelper'
{ withConvertedUserAndApiToken }       = require '../../../../../workers/social/testhelper/models/apitokenhelper'
{ generateSsoTokenLoginRequestParams } = require '../../../../testhelper/handler/ssotokenloginhelper'
{ createUserAndSsoToken }              = require '../../../../testhelper/handler/createssotokenhelper'

JUser    = require '../../../../models/user'
JAccount = require '../../../../models/account'

beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'server.handlers.api.ssotokenlogin', ->

  it 'should send HTTP 400 if api token is not set', (done) ->

    ssoTokenLoginRequestParams = generateSsoTokenLoginRequestParams
      body : { token : '' }

    request.post ssoTokenLoginRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'invalid request'
      done()


  it 'should send HTTP 400 if there is no username in jwt token', (done) ->

    ssoTokenLoginRequestParams = generateSsoTokenLoginRequestParams
      body : { token : JUser.createJWT { group : 'someGroup' } }

    request.post ssoTokenLoginRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'no username in token'
      done()


  it 'should send HTTP 400 if there is no group in jwt token', (done) ->

    ssoTokenLoginRequestParams = generateSsoTokenLoginRequestParams
      body : { token : JUser.createJWT { username : 'someUsername' } }

    request.post ssoTokenLoginRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'no group slug in token'
      done()


  it 'should send HTTP 400 if user is non-existent', (done) ->

    withConvertedUserAndApiToken { createGroup : yes }, ({ group }) ->
      token = JUser.createJWT { username: 'non-existent-user', group : group.slug }
      ssoTokenLoginRequestParams = generateSsoTokenLoginRequestParams
        body : { token }

      request.post ssoTokenLoginRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(body).to.be.equal 'invalid username!'
        done()


  it 'should send HTTP 400 if user is not a member of the apiToken group', (done) ->

    withConvertedUserAndApiToken { createGroup : yes }, ({ group, apiToken }) ->

      token    = null
      account  = null
      username = null

      queue = [

        ->
          # making a create user and create ssoToken request for that user
          createUserAndSsoToken apiToken.code, (data) ->
            { username, token } = data
            queue.next()

        ->
          # fetching account
          JAccount.one { 'profile.nickname' : username }, (err, account_) ->
            expect(err).to.not.exist
            account = account_
            queue.next()

        ->
          # leaving create user from api token group
          client = { connection : { delegate : account } }
          account.leaveFromAllGroups client, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # trying to use sso token without being a member of the group
          ssoTokenLoginRequestParams = generateSsoTokenLoginRequestParams
            body : { token }

          request.post ssoTokenLoginRequestParams, (err, res, body) ->
            expect(err).to.not.exist
            expect(res.statusCode).to.be.equal 400
            expect(body).to.be.equal 'user is not a member of the group'
            queue.next()

        -> done()

      ]

      daisy queue


beforeTests()

runTests()


