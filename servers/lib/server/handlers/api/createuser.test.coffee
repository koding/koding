{ daisy
  expect
  request
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity }          = require '../../../../testhelper'
{ withConvertedUser }               = require '../../../../../workers/social/testhelper'
{ withConvertedUserAndApiToken }    = require '../../../../../workers/social/testhelper/models/apitokenhelper'
{ generateCreateUserRequestParams } = require '../../../../testhelper/handler/createuserhelper'

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


  it 'should send HTTP 400 if given email is not in allowed domains', (done) ->

    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

      username = generateRandomUsername()
      createUserRequestParams = generateCreateUserRequestParams
        headers  : { Authorization : "Bearer #{apiToken.code}" }
        body     : { username, email : generateRandomEmail 'yandex.com' }

      expectedBody = 'Your email domain is not in allowed domains for this group'
      request.post createUserRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(JSON.parse body).to.be.deep.equal { error : apiErrors.invalidEmailDomain }
        done()


  it 'should send HTTP 403 if group.isApiEnabled is not true', (done) ->

    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ userFormData, apiToken, group }) ->

      # setting api token availability false for the group
      group.setApiTokenAvailability false, (err) ->
        expect(err).to.not.exist

        username = generateRandomUsername()
        createUserRequestParams = generateCreateUserRequestParams
          headers  : { Authorization : "Bearer #{apiToken.code}" }
          body     : { username, email : generateRandomEmail 'yandex.com' }

        expectedBody = 'api token usage is not enabled for this group'
        request.post createUserRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 403
          expect(JSON.parse body).to.be.deep.equal { error : apiErrors.apiTokenIsDisabled }
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

    values = [1, 3, 16]
    queue  = []

    values.forEach (length) ->
      queue.push ->
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
            queue.next()

    queue.push -> done()

    daisy queue


  it 'should send HTTP 400 when username length is not valid', (done) ->

    values = [1, 3, 26]
    queue  = []

    values.forEach (length) ->
      queue.push ->
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
            queue.next()

    queue.push -> done()

    daisy queue


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


beforeTests()

runTests()


