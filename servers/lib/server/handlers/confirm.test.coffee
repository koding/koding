{ async
  expect
  request
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity }       = require '../../../testhelper'
{ generateConfirmRequestParams } = require '../../../testhelper/handler/confirmhelper'
{ withRegisteredUser }           = require '../../../testhelper/handler/registerhelper'
{ createJWT }                    = require '../../../models/user'

JSession = require '../../../models/session'


beforeTests = -> before (done) ->

  checkBongoConnectivity done


runTests = -> describe 'server.handlers.confirm', ->

  it 'should send HTTP 400 when token is not provided', (done) ->

    withRegisteredUser ({ username }) ->

      confirmRequestParams = generateConfirmRequestParams
        qs : { token : '' }

      request.get confirmRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(body).be.empty
        done()


  it 'should send HTTP 500 when there is no token in JWT', (done) ->

    withRegisteredUser ({ username }) ->

      confirmRequestParams = generateConfirmRequestParams
        qs : { token : createJWT {} }

      request.get confirmRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 500
        expect(body).be.empty
        done()


  it 'should send HTTP 500 when user is not a registered one', (done) ->

    username = generateRandomUsername()
    jwtToken = createJWT { username }

    confirmRequestParams = generateConfirmRequestParams
      qs : { token : jwtToken }

    request.get confirmRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 500
      expect(body).be.empty
      done()


  it 'should send HTTP 200 when token and user are both valid', (done) ->

    username  = generateRandomUsername()
    groupName = generateRandomString()

    withRegisteredUser ({ username }) ->

      jwtToken = createJWT { username, groupName }

      queue = [

        (next) ->
          confirmRequestParams = generateConfirmRequestParams
            qs : { token : jwtToken }

          request.get confirmRequestParams, (err, res, body) ->
            expect(err).to.not.exist
            expect(res.statusCode).to.be.equal 200
            expect(body).not.to.be.empty
            next()

        (next) ->
          # expecting a session to be created
          JSession.one { username, groupName }, (err, session) ->
            expect(err).to.not.exist
            expect(session).to.exist
            next()

      ]

      async.series queue, done


beforeTests()

runTests()
