Bongo                               = require 'bongo'
koding                              = require './../bongo'

{ daisy }                           = Bongo
{ expect }                          = require 'chai'
{ generateRandomEmail
  generateRandomString
  RegisterHandlerHelper }           = require '../../../testhelper'

{ generateCheckTokenRequestParams
  generateCreateTeamRequestParams } = require '../../../testhelper/handler/teamhelper'

request                             = require 'request'

JInvitation                         = null


# here we have actual tests
runTests = -> describe 'server.handlers.checktoken', ->

  beforeEach (done) ->

    # including models before each test case, requiring them outside of
    # tests suite is causing undefined errors
    { JInvitation } = koding.models
    done()


  it 'should send HTTP 400 if token is not set', (done) ->

    checkTokenPostParams = generateCheckTokenRequestParams
      body     :
        token  : ''

    request.post checkTokenPostParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      expect(body)            .to.be.equal 'token is required'
      done()


  it 'should send HTTP 404 if token is invalid', (done) ->

    checkTokenPostParams = generateCheckTokenRequestParams
      body     :
        token  : 'someInvalidToken'

    request.post checkTokenPostParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 404
      expect(body)            .to.be.equal 'invitation not found'
      done()


  it 'should send HTTP 200 if token is valid', (done) ->

    token                   = ''
    inviteeEmail            = generateRandomEmail()

    queue = [

      ->
        options = { body : { invitees : inviteeEmail } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          # expecting HTTP 200 status code
          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            queue.next()

      ->
        # expecting invitation to be created
        params = { email : inviteeEmail }

        JInvitation.one params, (err, invitation) ->
          expect(err)                   .to.not.exist
          expect(invitation)            .to.exist
          expect(invitation.code)       .to.exist
          expect(invitation.email)      .to.be.equal inviteeEmail
          expect(invitation.status)     .to.be.equal 'pending'

          # saving user invitation token
          token = invitation.code
          queue.next()

      ->
        # expecting newly created invitation token to be validated
        checkTokenPostParams = generateCheckTokenRequestParams
          body     :
            token  : token

        request.post checkTokenPostParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      -> done()

    ]

    daisy queue


runTests()
