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
      qs : { token : '' }

    request.get ssoTokenLoginRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'token is required'
      done()


  it 'should send HTTP 400 if there is no username in jwt token', (done) ->

    ssoTokenLoginRequestParams = generateSsoTokenLoginRequestParams
      qs : { token : JUser.createJWT { group : 'someGroup' } }

    request.get ssoTokenLoginRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'no username in token'
      done()


  it 'should send HTTP 400 if there is no group in jwt token', (done) ->

    ssoTokenLoginRequestParams = generateSsoTokenLoginRequestParams
      qs : { token : JUser.createJWT { username : 'someUsername' } }

    request.get ssoTokenLoginRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'no group slug in token'
      done()


  it 'should send HTTP 400 if user is non-existent', (done) ->

    withConvertedUserAndApiToken { createGroup : yes }, ({ group }) ->
      token = JUser.createJWT { username: 'non-existent-user', group : group.slug }
      ssoTokenLoginRequestParams = generateSsoTokenLoginRequestParams
        qs  : { token }
        url : { subdomain : group.slug }

      request.get ssoTokenLoginRequestParams, (err, res, body) ->
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
            qs : { token }
            url : { subdomain : group.slug }

          request.get ssoTokenLoginRequestParams, (err, res, body) ->
            expect(err).to.not.exist
            expect(res.statusCode).to.be.equal 400
            expect(body).to.be.equal 'user is not a member of the group'
            queue.next()

        -> done()

      ]

      daisy queue


  it 'should send HTTP and be able to login user with valid request', (done) ->

    withConvertedUserAndApiToken { createGroup : yes }, ({ group, apiToken }) ->
      createUserAndSsoToken apiToken.code, ({ token }) ->

        ssoTokenLoginRequestParams = generateSsoTokenLoginRequestParams
          qs : { token }
          url : { subdomain : group.slug }

        request.get ssoTokenLoginRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          expect(body).not.to.be.empty
          done()



beforeTests()

runTests()


