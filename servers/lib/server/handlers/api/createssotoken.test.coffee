{ daisy
  expect
  request
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity }              = require '../../../../testhelper'
{ withConvertedUser }                   = require '../../../../../workers/social/testhelper'
{ withConvertedUserAndApiToken }        = require '../../../../../workers/social/testhelper/models/apitokenhelper'
{ generateCreateSsoTokenRequestParams } = require '../../../../testhelper/handler/createssotokenhelper'

beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'server.handlers.api.createssotoken', ->

  it 'should send HTTP 401 if Authorization: Bearer header is not set', (done) ->

    createSsoTokenRequestParams = generateCreateSsoTokenRequestParams
      headers : { Authorization : '' }

    request.post createSsoTokenRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 401
      expect(body).to.be.equal 'unauthorized request'
      done()


  it 'should send HTTP 400 if api token is non-existent', (done) ->

    createSsoTokenRequestParams = generateCreateSsoTokenRequestParams()

    request.post createSsoTokenRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'invalid token!'
      done()


  it 'should send HTTP 400 if username is not set', (done) ->

    createSsoTokenRequestParams = generateCreateSsoTokenRequestParams
      body : { username : '' }

    request.post createSsoTokenRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'invalid request'
      done()


  it 'should send HTTP 400 if user is non-existent', (done) ->

    options = { createGroup : yes, groupData : { isApiTokenEnabled : yes } }
    withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

      createSsoTokenRequestParams = generateCreateSsoTokenRequestParams
        headers : { Authorization : "Bearer #{apiToken.code}" }
        body    : { username : 'non-existent-username' }

      request.post createSsoTokenRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(body).to.be.equal 'invalid username!'
        done()


  it 'should send HTTP 400 if user is not a member of the api token group', (done) ->

    # creating user, group, and api token
    options = { createGroup : yes, groupData : { isApiTokenEnabled : yes } }
    withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

      # creating another user, which is not a member of the previously created group
      withConvertedUser ({ userFormData }) ->
        anotherUsername = userFormData.username

        createSsoTokenRequestParams = generateCreateSsoTokenRequestParams
          headers : { Authorization : "Bearer #{apiToken.code}" }
          body    : { username : anotherUsername }

        request.post createSsoTokenRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 400
          expect(body).to.be.equal 'invalid request'
          done()


  it 'should send HTTP 200 with token in body if request is valid', (done) ->

    # creating user, group, and api token
    options = { createGroup : yes, groupData : { isApiTokenEnabled : yes } }
    withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

      createSsoTokenRequestParams = generateCreateSsoTokenRequestParams
        headers : { Authorization : "Bearer #{apiToken.code}" }
        body    : { username : userFormData.username }

      request.post createSsoTokenRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 200
        expect(body).to.contain 'token'
        expect(body).to.contain 'loginUrl'
        done()


beforeTests()

runTests()
