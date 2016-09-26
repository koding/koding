{ expect
  request
  generateUrl
  deepObjectExtend
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity
  generateRequestParamsEncodeBody } = require '../../../../testhelper'

{ withConvertedUser }               = require '../../../../../workers/social/testhelper'
{ withConvertedUserAndApiToken }    = require '../../../../../workers/social/testhelper/models/apitokenhelper'

apiErrors                           = require './errors'
KodingLogger                        = require '../../../../models/kodinglogger'


generateLogRequestParams = (opts = {}, subdomain, query) ->

  query    ?= ''
  params    =
    url     : generateUrl { route : "-/api/logs#{query}", subdomain }
    query   : {}
    headers : { Authorization : "Bearer #{generateRandomString()}" }

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


TESTUSERS =
  admin   : null
  regular : null
  team    : null

TESTLOG   = generateRandomString()

# use different scope on each test ~ GG
TESTSCOPE = KodingLogger.SCOPES[Math.round(Math.random() * (KodingLogger.SCOPES.length - 1))]


beforeTests = -> before (done) ->

  KodingLogger.connect()

  checkBongoConnectivity ->

    withConvertedUser (regular) ->
      TESTUSERS.regular = regular

      withConvertedUser { role: 'admin' }, (admin) ->
        TESTUSERS.admin = admin

        KodingLogger[TESTSCOPE] TESTUSERS.admin.group.slug, TESTLOG

        options = { createGroup : yes, groupData : { isApiEnabled : yes } }

        withConvertedUserAndApiToken options, (team) ->
          TESTUSERS.team = team

          KodingLogger[TESTSCOPE] TESTUSERS.team.group.slug, TESTLOG

          done()


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


  it 'should send HTTP 401 if no api token provided and session not belongs to an admin', (done) ->

    { client } = TESTUSERS.regular

    logRequestParams = generateRequestParamsEncodeBody
      url      : generateUrl { route : '-/api/logs' }
      clientId : client.sessionToken

    request.get logRequestParams, (err, res, body) ->

      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 401
      expect(JSON.parse body).to.be.deep.equal { error : apiErrors.unauthorizedRequest }

      done()


  it 'should send HTTP 403 if group.isApiEnabled is not true', (done) ->

    { client, apiToken, group } = TESTUSERS.team

    # setting api token availability false for the group
    group.modify client, { isApiEnabled: false }, (err) ->

      expect(err).to.not.exist

      logRequestParams = generateLogRequestParams
        headers : { Authorization : "Bearer #{apiToken.code}" }

      request.get logRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 403
        expect(JSON.parse body).to.be.deep.equal { error : apiErrors.apiIsDisabled }

        # revert api token availability to true for the group
        group.modify client, { isApiEnabled: true }, (err) ->
          expect(err).to.not.exist
          done()


  it 'should send HTTP 400 if provided token valid but not subdomain', (done) ->

    { client, apiToken, group } = TESTUSERS.team

    logRequestParams = generateLogRequestParams
      headers : { Authorization : "Bearer #{apiToken.code}" }

    request.get logRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(JSON.parse body).to.be.deep.equal {
        error: apiErrors.invalidRequestDomain
      }

      done()


  it.skip 'should send HTTP 200 if provided token and request domain is valid', (done) ->

    { client, apiToken, group } = TESTUSERS.team

    logRequestParams = generateLogRequestParams
      headers : { Authorization : "Bearer #{apiToken.code}" }
    , group.slug

    request.get logRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 200
      expect(body).to.contain 'data'

      done()


  it.skip 'should send HTTP 200 if token not provided but there is a valid session', (done) ->

    { client } = TESTUSERS.admin

    logRequestParams = generateRequestParamsEncodeBody
      url      : generateUrl { route : '-/api/logs' }
      clientId : client.sessionToken

    request.get logRequestParams, (err, res, body) ->

      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 200
      expect(body).to.contain 'data'

      done()


  it.skip 'should send HTTP 200 and the result in data if session is valid', (done) ->

    { client, group } = TESTUSERS.admin

    logRequestParams = generateRequestParamsEncodeBody
      url      : generateUrl { route : "-/api/logs?q=#{TESTLOG}" }
      clientId : client.sessionToken

    identifier = KodingLogger.getIdentifier TESTSCOPE, group.slug

    request.get logRequestParams, (err, res, body) ->

      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 200
      expect(body).to.contain 'data'
      expect((JSON.parse body).data.logs).to.exist
      expect((JSON.parse body).data.logs).to.have.length 1
      expect((JSON.parse body).data.logs[0].message).to.be.equal "#{identifier} #{TESTLOG}"

      done()


  it.skip 'should send HTTP 200 and the result in data if apiToken is valid', (done) ->

    { apiToken, group } = TESTUSERS.team

    logRequestParams = generateLogRequestParams
      headers : { Authorization : "Bearer #{apiToken.code}" }
    , group.slug
    , "?q=#{TESTLOG}"

    identifier = KodingLogger.getIdentifier TESTSCOPE, group.slug

    request.get logRequestParams, (err, res, body) ->

      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 200
      expect(body).to.contain 'data'
      expect((JSON.parse body).data.logs).to.exist
      expect((JSON.parse body).data.logs).to.have.length 1
      expect((JSON.parse body).data.logs[0].message).to.be.equal "#{identifier} #{TESTLOG}"

      done()


beforeTests()

runTests()
