{ expect
  request
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity }              = require '../../../../testhelper'
{ withConvertedUser }                   = require '../../../../../workers/social/testhelper'
{ withConvertedUserAndApiToken }        = require '../../../../../workers/social/testhelper/models/apitokenhelper'
{ generateCreateSsoTokenRequestParams } = require '../../../../testhelper/handler/createssotokenhelper'

apiErrors = require './errors'

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
      expect(JSON.parse body).to.be.deep.equal { error : apiErrors.unauthorizedRequest }
      done()


  it 'should send HTTP 400 if api token is non-existent', (done) ->

    createSsoTokenRequestParams = generateCreateSsoTokenRequestParams()

    request.post createSsoTokenRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(JSON.parse body).to.be.deep.equal { error : apiErrors.invalidApiToken }
      done()


  it 'should send HTTP 400 if username is not set', (done) ->

    createSsoTokenRequestParams = generateCreateSsoTokenRequestParams
      body : { username : '' }

    request.post createSsoTokenRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(JSON.parse body).to.be.deep.equal { error : apiErrors.invalidUsername }
      done()


  it 'should send HTTP 400 if user is non-existent', (done) ->

    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ userFormData, apiToken }) ->

      createSsoTokenRequestParams = generateCreateSsoTokenRequestParams
        headers : { Authorization : "Bearer #{apiToken.code}" }
        body    : { username : 'non-existent-username' }

      request.post createSsoTokenRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(JSON.parse body).to.be.deep.equal { error : apiErrors.invalidUsername }
        done()


  it 'should send HTTP 400 if user is not a member of the api token group', (done) ->

    # creating user, group, and api token
    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
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
          expect(JSON.parse body).to.be.deep.equal { error : apiErrors.notGroupMember }
          done()


  it 'should send HTTP 403 if group.isApiEnabled is not true', (done) ->

    # creating user, group, and api token
    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ client, userFormData, apiToken, group }) ->

      # setting api token availability false for the group
      group.modify client, { isApiEnabled : false }, (err) ->
        expect(err).to.not.exist

        createSsoTokenRequestParams = generateCreateSsoTokenRequestParams
          headers : { Authorization : "Bearer #{apiToken.code}" }
          body    : { username : userFormData.username }

        request.post createSsoTokenRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 403
          expect(JSON.parse body).to.be.deep.equal { error : apiErrors.apiIsDisabled }
          done()


  it 'should send HTTP 200 with token in body if request is valid', (done) ->

    # creating user, group, and api token
    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
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
