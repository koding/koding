{ daisy
  expect
  request
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity }          = require '../../../../testhelper'
{ withConvertedUser }               = require '../../../../../workers/social/testhelper'
{ withConvertedUserAndApiToken }    = require '../../../../../workers/social/testhelper/models/apitokenhelper'

JUser = require '../../../../models/user'

beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'server.handlers.api.createuser', ->

  it 'should send HTTP 401 if Authorization: Bearer header is not set', (done) ->

    createUserRequestParams = generateCreateUserRequestParams
      headers : { Authorization : '' }

    request.post createUserRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 401
      expect(body).to.be.equal 'unauthorized request'
      done()


  it 'should send HTTP 400 if api token is non-existent', (done) ->

    createUserRequestParams = generateCreateUserRequestParams()

    request.post createUserRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'invalid token!'
      done()


  it 'should send HTTP 400 if email is not set', (done) ->

    withConvertedUserAndApiToken ({ userFormData, apiToken }) ->
      createUserRequestParams = generateCreateUserRequestParams
        headers  : { Authorization : "Bearer #{apiToken.code}" }
        body     : { email  : '' }

      request.post createUserRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(body).to.be.equal 'invalid request'
        done()


  it 'should send HTTP 400 if username is already in use', (done) ->

    withConvertedUserAndApiToken ({ userFormData, apiToken }) ->
      createUserRequestParams = generateCreateUserRequestParams
        headers  : { Authorization : "Bearer #{apiToken.code}" }
        body     : { username : userFormData.username }

      request.post createUserRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(body).to.be.equal 'username is not available'
        done()


  it 'should send HTTP 400 if username is a banned one', (done) ->

    withConvertedUserAndApiToken ({ userFormData, apiToken }) ->
      createUserRequestParams = generateCreateUserRequestParams
        headers  : { Authorization : "Bearer #{apiToken.code}" }
        body     : { username : JUser.bannedUserList[0] }

      request.post createUserRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(body).to.be.equal 'username is not available'
        done()


  it 'should send HTTP 400 if email is in use', (done) ->

    withConvertedUserAndApiToken ({ userFormData, apiToken }) ->
      createUserRequestParams = generateCreateUserRequestParams
        headers  : { Authorization : "Bearer #{apiToken.code}" }
        body     : { email : userFormData.email }

      # api token creator tries to register himself
      request.post createUserRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(body).to.be.equal 'Email is already in use!'
        done()


  it 'should send HTTP 400 if given email is not in allowed domains', (done) ->

    withConvertedUserAndApiToken ({ userFormData, apiToken }) ->

      username = generateRandomUsername()
      createUserRequestParams = generateCreateUserRequestParams
        headers  : { Authorization : "Bearer #{apiToken.code}" }
        body     : { username, email : generateRandomEmail 'yandex.com' }

      expectedBody = 'Your email domain is not in allowed domains for this group'
      request.post createUserRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(body).to.be.equal expectedBody
        done()


  describe 'when request is valid', ->

    it 'should send HTTP 200 and create user with username provided', (done) ->

      withConvertedUserAndApiToken ({ userFormData, apiToken }) ->

        username = generateRandomUsername()
        password = passwordConfirm = generateRandomString()

        createUserRequestParams = generateCreateUserRequestParams
          headers  : { Authorization : "Bearer #{apiToken.code}" }
          body     : { username }

        # creating user
        request.post createUserRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          expect(body).to.contain username
          done()

    it 'should send HTTP 200 and create user without username provided', (done) ->

      withConvertedUserAndApiToken ({ userFormData, apiToken }) ->

        password = passwordConfirm = generateRandomString()

        createUserRequestParams = generateCreateUserRequestParams
          headers  : { Authorization : "Bearer #{apiToken.code}" }
          body     : { username : '' }

        # expecting to see randomly generated username
        request.post createUserRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          expect(body).to.contain apiToken.group.substring 0, 4
          done()


beforeTests()

runTests()


