{ daisy
  expect
  request
  generateUrl
  deepObjectExtend
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity
  generateRequestParamsEncodeBody } = require '../../../../testhelper'

{ withConvertedUser }               = require '../../../../../workers/social/testhelper'
{ withConvertedUserAndApiToken }    = require '../../../../../workers/social/testhelper/models/apitokenhelper'

apiErrors = require './errors'

generateLogRequestParams = (opts = {}, subdomain) ->

  params    =
    url     : generateUrl { route : '-/api/logs', subdomain }
    query   : {}
    headers : { Authorization : "Bearer #{generateRandomString()}" }

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams

beforeTests = -> before (done) ->

  checkBongoConnectivity done


runTests = -> describe 'server.handlers.api.logs', ->


  it 'should send HTTP 400 if provided api token is not valid', (done) ->

    logRequestParams = generateLogRequestParams()

    request.get logRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(JSON.parse body).to.be.deep.equal { error : apiErrors.invalidApiToken }

      done()


  it 'should send HTTP 401 if api token is not provided and there is no session', (done) ->

    logRequestParams = generateRequestParamsEncodeBody
      url            : generateUrl { route : '-/api/logs' }

    request.get logRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 401
      expect(JSON.parse body).to.be.deep.equal { error : apiErrors.unauthorizedRequest }

      done()


  it 'should send HTTP 403 if group.isApiEnabled is not true', (done) ->

    # creating user, group, and api token
    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ client, userFormData, apiToken, group }) ->

      # setting api token availability false for the group
      group.modify client, { isApiEnabled: false }, (err) ->

        expect(err).to.not.exist

        logRequestParams = generateLogRequestParams
          headers : { Authorization : "Bearer #{apiToken.code}" }

        request.get logRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 403
          expect(JSON.parse body).to.be.deep.equal { error : apiErrors.apiIsDisabled }

          done()


  it 'should send HTTP 400 if provided token valid but not subdomain', (done) ->

    # creating user, group, and api token
    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ group, account, apiToken }) ->

      logRequestParams = generateLogRequestParams
        headers : { Authorization : "Bearer #{apiToken.code}" }

      request.get logRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(JSON.parse body).to.be.deep.equal {
          error: apiErrors.invalidRequestDomain
        }

        done()


  it 'should send HTTP 200 if provided token and request domain is valid', (done) ->

    # creating user, group, and api token
    options = { createGroup : yes, groupData : { isApiEnabled : yes } }
    withConvertedUserAndApiToken options, ({ group, account, apiToken }) ->

      logRequestParams = generateLogRequestParams
        headers : { Authorization : "Bearer #{apiToken.code}" }
      , group.slug

      request.get logRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 200
        expect(body).to.contain 'data'

        done()


  it 'should send HTTP 200 if token not provided but there is a valid session', (done) ->

    withConvertedUser ({ group, account, client }) ->

      logRequestParams = generateRequestParamsEncodeBody
        url      : generateUrl { route : '-/api/logs' }
        clientId : client.sessionToken

      request.get logRequestParams, (err, res, body) ->

        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 200
        expect(body).to.contain 'data'

        done()


beforeTests()

runTests()
