{ async
  expect
  request
  generateRandomEmail
  generateRandomString }            = require '../../../testhelper'
{ generateCheckTokenRequestParams
  generateCreateTeamRequestParams } = require '../../../testhelper/handler/teamhelper'

JInvitation = require '../../../models/invitation'


# here we have actual tests
runTests = -> describe 'server.handlers.checktoken', ->

  it 'should send HTTP 400 if token is not set', (done) ->

    checkTokenPostParams = generateCheckTokenRequestParams
      body    :
        token : ''

    request.post checkTokenPostParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'token is required'
      done()


  it 'should send HTTP 404 if token is invalid', (done) ->

    checkTokenPostParams = generateCheckTokenRequestParams
      body    :
        token : 'someInvalidToken'

    request.post checkTokenPostParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 404
      expect(body).to.be.equal 'invitation not found'
      done()


  it 'should send HTTP 200 if token is valid', (done) ->

    token        = ''
    inviteeEmail = generateRandomEmail()

    queue = [

      (next) ->
        options = { body : { invitees : inviteeEmail } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          # expecting HTTP 200 status code
          request.post createTeamRequestParams, (err, res, body) ->
            expect(err).to.not.exist
            expect(res.statusCode).to.be.equal 200
            next()

      (next) ->
        # expecting invitation to be created
        params = { email : inviteeEmail }

        JInvitation.one params, (err, invitation) ->
          expect(err).to.not.exist
          expect(invitation).to.exist
          expect(invitation.code).to.exist
          expect(invitation.email).to.be.equal inviteeEmail
          expect(invitation.status).to.be.equal 'pending'

          # saving user invitation token
          token = invitation.code
          next()

      (next) ->
        # expecting newly created invitation token to be validated
        checkTokenPostParams = generateCheckTokenRequestParams
          body    :
            token : token

        request.post checkTokenPostParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          next()

    ]

    async.series queue, done


runTests()
