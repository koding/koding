{ async
  expect
  request
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity }          = require '../../../../testhelper'
{ withConvertedUser }               = require '../../../../../workers/social/testhelper'
{ withConvertedUserAndApiToken }    = require '../../../../../workers/social/testhelper/models/apitokenhelper'
{ generateCreateUserRequestParams } = require '../../../../testhelper/handler/createuserhelper'
{ SUGGESTED_USERNAME_MIN_LENGTH
  SUGGESTED_USERNAME_MAX_LENGTH }   = require './helpers'

apiErrors = require './errors'
JUser     = require '../../../../models/user'

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
      expect(JSON.parse body).to.be.deep.equal { error : apiErrors.unauthorizedRequest }
      done()


  it 'should send HTTP 400 if api token is non-existent', (done) ->

    createUserRequestParams = generateCreateUserRequestParams()

    request.post createUserRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(JSON.parse body).to.be.deep.equal { error : apiErrors.invalidApiToken }
      done()


  it 'should send HTTP 400 if email is not set', (done) ->

    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

      createUserRequestParams = generateCreateUserRequestParams
        headers  : { Authorization : "Bearer #{apiToken.code}" }
        body     : { email  : '' }

      request.post createUserRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(JSON.parse body).to.be.deep.equal { error : apiErrors.invalidInput }
        done()


  it 'should send HTTP 409 if username is already in use', (done) ->

    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

      createUserRequestParams = generateCreateUserRequestParams
        headers  : { Authorization : "Bearer #{apiToken.code}" }
        body     : { username : userFormData.username }

      request.post createUserRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 409
        expect(JSON.parse body).to.be.deep.equal { error : apiErrors.usernameAlreadyExists }
        done()


  it 'should send HTTP 409 if username is a banned one', (done) ->

    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

      createUserRequestParams = generateCreateUserRequestParams
        headers  : { Authorization : "Bearer #{apiToken.code}" }
        body     : { username : JUser.bannedUserList[0] }

      request.post createUserRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 409
        expect(JSON.parse body).to.be.deep.equal { error : apiErrors.usernameAlreadyExists }
        done()


  it 'should send HTTP 500 if username has invalid characters', (done) ->

    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

      createUserRequestParams = generateCreateUserRequestParams
        headers  : { Authorization : "Bearer #{apiToken.code}" }
        body     : { username : "@$_?()=&#{generateRandomString(10)}" }

      request.post createUserRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 500
        expect(JSON.parse body).to.be.deep.equal { error : apiErrors.internalError }
        done()


  it 'should send HTTP 409 if email is in use', (done) ->

    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

      createUserRequestParams = generateCreateUserRequestParams
        headers  : { Authorization : "Bearer #{apiToken.code}" }
        body     : { email : userFormData.email }

      # api token creator tries to register himself
      request.post createUserRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 409
        expect(JSON.parse body).to.be.deep.equal { error : apiErrors.emailAlreadyExists }
        done()


  it 'should send HTTP 403 if group.isApiEnabled is not true', (done) ->

    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ client, userFormData, apiToken, group }) ->

      # setting api token availability false for the group
      group.modify client, { isApiEnabled : false }, (err) ->
        expect(err).to.not.exist

        username = generateRandomUsername()
        createUserRequestParams = generateCreateUserRequestParams
          headers  : { Authorization : "Bearer #{apiToken.code}" }
          body     : { username, email : generateRandomEmail 'yandex.com' }

        expectedBody = 'api token usage is not enabled for this team'
        request.post createUserRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 403
          expect(JSON.parse body).to.be.deep.equal { error : apiErrors.apiIsDisabled }
          done()


  it 'should send HTTP 400 when both username and suggestedUsername not present', (done) ->

    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

      username = generateRandomUsername()

      createUserRequestParams = generateCreateUserRequestParams
        headers  : { Authorization : "Bearer #{apiToken.code}" }
        body     : { username : '', suggestedUsername : '' }

      # creating user
      request.post createUserRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(JSON.parse body).to.be.deep.equal { error : apiErrors.invalidInput }
        done()


  it 'should send HTTP 400 when suggested username length is not valid', (done) ->

    values = [SUGGESTED_USERNAME_MIN_LENGTH - 1, SUGGESTED_USERNAME_MAX_LENGTH + 1]
    queue  = []

    values.forEach (length) ->
      queue.push (next) ->
        options = { createGroup : yes, groupData : { isApiEnabled : yes } }
        withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

          suggestedUsername = generateRandomString length

          createUserRequestParams = generateCreateUserRequestParams
            headers  : { Authorization : "Bearer #{apiToken.code}" }
            body     : { username : '', suggestedUsername }

          # creating user
          request.post createUserRequestParams, (err, res, body) ->
            expect(err).to.not.exist
            expect(res.statusCode).to.be.equal 400
            expect(JSON.parse body).to.be.deep.equal { error : apiErrors.outOfRangeSuggestedUsername }
            next()

    async.series queue, done


  it 'should send HTTP 400 when username length is not valid', (done) ->

    { minLength, maxLength } = JUser.getValidUsernameLengthRange()
    values = [minLength - 1, maxLength + 1]
    queue  = []

    values.forEach (length) ->
      queue.push (next) ->
        options = { createGroup : yes, groupData : { isApiEnabled : yes } }
        withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

          username = generateRandomString length

          createUserRequestParams = generateCreateUserRequestParams
            headers  : { Authorization : "Bearer #{apiToken.code}" }
            body     : { username }

          # creating user
          request.post createUserRequestParams, (err, res, body) ->
            expect(err).to.not.exist
            expect(res.statusCode).to.be.equal 400
            expect(JSON.parse body).to.be.deep.equal { error : apiErrors.outOfRangeUsername }
            next()

    async.series queue, done


  describe 'when request is valid', ->

    it 'should send HTTP 200 and create user with username provided', (done) ->

      options = { createGroup : yes, groupData : { isApiEnabled : yes } }
      withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

        username = generateRandomUsername()

        createUserRequestParams = generateCreateUserRequestParams
          headers  : { Authorization : "Bearer #{apiToken.code}" }
          body     : { username }

        # creating user
        request.post createUserRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          expect(JSON.parse body).to.be.deep.equal { data : { username } }
          done()


    it 'should send HTTP 200 and create user with suggested username', (done) ->

      options = { createGroup : yes, groupData : { isApiEnabled : yes } }
      withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

        suggestedUsername = generateRandomString 10

        createUserRequestParams = generateCreateUserRequestParams
          headers  : { Authorization : "Bearer #{apiToken.code}" }
          body     : { username : '', suggestedUsername }

        # expecting to see randomly generated username
        request.post createUserRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          expect(body).to.contain suggestedUsername
          done()


    it 'should send HTTP 200 and use suggestedUsername if username is invalid', (done) ->

      options = { createGroup : yes, groupData : { isApiEnabled : yes } }
      withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

        suggestedUsername = generateRandomString 10

        createUserRequestParams = generateCreateUserRequestParams
          headers  : { Authorization : "Bearer #{apiToken.code}" }
          body     : { username : userFormData.username, suggestedUsername }

        # expecting to see randomly generated username
        request.post createUserRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          expect(body).to.contain suggestedUsername
          done()


    it 'should send HTTP 200 even if given email is not in allowed domains', (done) ->

      groupData = { allowedDomains : [], isApiEnabled : yes }
      options = { createGroup : yes, groupData }
      withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

        username = generateRandomUsername()
        createUserRequestParams = generateCreateUserRequestParams
          headers  : { Authorization : "Bearer #{apiToken.code}" }
          body     : { username, email : generateRandomEmail() }

        request.post createUserRequestParams, (err, res, body) ->
          expect(err?.message).to.not.exist
          expect(JSON.parse body).to.be.deep.equal { data : { username } }
          expect(res.statusCode).to.be.equal 200
          done()



beforeTests()

runTests()
