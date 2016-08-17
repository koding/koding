{ async
  expect
  request
  getCookiesFromHeader
  generateRandomUsername
  checkBongoConnectivity } = require '../../../testhelper'

{ createJWT } = require '../../../models/user'
{ withRegisteredUser } = require '../../../testhelper/handler/registerhelper'
{ generateLoginWithTokenRequestParams } = require '../../../testhelper/handler/loginwithtokenhelper'


before (done) -> checkBongoConnectivity done


describe 'server.handlers.confirm', ->

  it 'should send HTTP 400 when token is not provided', (done) ->

    withRegisteredUser ({ username }) ->

      loginWithTokenRequestParams = generateLoginWithTokenRequestParams
        qs : { token : '' }

      request.get loginWithTokenRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(body).to.be.equal 'Token is not set'
        done()


  it 'should send HTTP 400 when there is no username in JWT', (done) ->

    withRegisteredUser ({ username }) ->

      loginWithTokenRequestParams = generateLoginWithTokenRequestParams
        qs : { token : createJWT { username: '', groupName: '' } }

      request.get loginWithTokenRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(body).to.be.equal 'no username in token'
        done()

  it 'should send HTTP 400 when there is no groupName in JWT', (done) ->

    withRegisteredUser ({ username }) ->

      loginWithTokenRequestParams = generateLoginWithTokenRequestParams
        qs : { token : createJWT { username, groupName: '' } }

      request.get loginWithTokenRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(body).to.be.equal 'no groupName in token'
        done()


  it 'should send HTTP 400 when user is not a registered one', (done) ->

    jwtToken = createJWT {
      username: generateRandomUsername()
      groupName: 'koding'
    }

    loginWithTokenRequestParams = generateLoginWithTokenRequestParams
      qs : { token : jwtToken }

    request.get loginWithTokenRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'Account not found'
      done()

  it 'should send HTTP 400 when group is not a registered one', (done) ->

    withRegisteredUser ({ username }) ->

      jwtToken = createJWT { username, groupName: generateRandomUsername() }

      loginWithTokenRequestParams = generateLoginWithTokenRequestParams
        qs : { token : jwtToken }

      request.get loginWithTokenRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 400
        expect(body).to.be.equal 'Group not found'
        done()


  it 'should send HTTP 200 when token and user are both valid', (done) ->

    withRegisteredUser ({ username }) ->

      queue = [

        (next) ->
          loginWithTokenRequestParams = generateLoginWithTokenRequestParams
            qs : { token : createJWT { username, groupName: 'koding' } }

          request.get loginWithTokenRequestParams, (err, res, body) ->
            expect(err).to.not.exist
            expect(res.statusCode).to.be.equal 200

            cookees = getCookiesFromHeader res.headers
            clientCookees = cookees.filter (cookee) -> cookee.key is 'clientId'
            expect(clientCookees).to.have.length.above(0)

            next()
      ]

      async.series queue, done
