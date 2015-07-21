Bongo                                     = require 'bongo'
koding                                    = require './../bongo'
request                                   = require 'request'
querystring                               = require 'querystring'

{ daisy }                                 = Bongo
{ expect }                                = require 'chai'
{ generateRandomEmail
  generateRandomString
  generateRandomUsername

  ResetHandlerHelper
  RegisterHandlerHelper }                 = require '../../../testhelper'

{ generateResetRequestParams  }          = ResetHandlerHelper
{ generateRegisterRequestParams }        = RegisterHandlerHelper

JUser                                    = null
JPasswordRecovery                        = null

# here we have actual tests
runTests = -> describe 'server.handlers.reset', ->

  beforeEach (done) ->

    # including models before each test case, requiring them outside of
    # tests suite is causing undefined errors
    { JUser
      JPasswordRecovery } = koding.models

    done()


  it 'should send HTTP 404 if request method is not POST', (done) ->

    resetRequestParams = generateResetRequestParams()

    queue       = []
    methods     = ['put', 'patch', 'delete']

    addRequestToQueue = (queue, method) -> queue.push ->
      resetRequestParams.method = method
      request resetRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 404
        queue.next()

    for method in methods
      addRequestToQueue queue, method

    queue.push -> done()

    daisy queue


  it 'should send HTTP 400 if token is not set', (done) ->

    resetRequestParams = generateResetRequestParams
      body            :
        password      : generateRandomString()
        recoveryToken : ''

    request.post resetRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      expect(body)            .to.be.equal 'Invalid token!'
      done()


  it 'should send HTTP 400 if password is not set', (done) ->

    resetRequestParams = generateResetRequestParams
      body            :
        password      : ''
        recoveryToken : generateRandomString()

    request.post resetRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      expect(body)            .to.be.equal 'Invalid password!'
      done()


  it 'should send HTTP 400 if token is not found', (done) ->

    resetRequestParams = generateResetRequestParams
      body            :
        password      : generateRandomString()
        recoveryToken : generateRandomString()

    request.post resetRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      expect(body)            .to.be.equal 'Invalid token.'
      done()


  it 'should send HTTP 400 if token is not active', (done) ->

    email        = generateRandomEmail()
    token        = generateRandomString()
    username     = generateRandomUsername()
    certificate  = null
    expiryPeriod = ResetHandlerHelper.defaultExpiryPeriod
    expectedBody = """
      This password recovery certificate cannot be redeemed.
    """

    resetRequestParams = generateResetRequestParams
      body            :
        password      : generateRandomString()
        recoveryToken : token

    queue = [

      ->
        # generating a new certificate and saving it
        certificate = new JPasswordRecovery
          email        : email
          token        : token
          status       : 'active'
          username     : username
          expiryPeriod : expiryPeriod

        certificate.save (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # redeeming certificate without before reset request
        certificate.redeem (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting failure because certificate status is redeemed
        request.post resetRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 400
          expect(body)            .to.be.equal expectedBody
          queue.next()

      ->
        # expiring certificate before reset request
        certificate.expire (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting failure because certificate status is expired
        request.post resetRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 400
          expect(body)            .to.be.equal expectedBody
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 400 if token is valid but user doesnt exist', (done) ->

    email        = generateRandomEmail()
    token        = generateRandomString()
    username     = generateRandomUsername()
    certificate  = null
    expiryPeriod = ResetHandlerHelper.defaultExpiryPeriod

    resetRequestParams = generateResetRequestParams
      body            :
        password      : generateRandomString()
        recoveryToken : token

    queue = [

      ->
        # generating a new certificate and saving it
        certificate = new JPasswordRecovery
          email        : email
          token        : token
          status       : 'active'
          username     : username
          expiryPeriod : expiryPeriod

        certificate.save (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting failure because user doesn't exist
        expectedBody = 'Unknown user!'
        request.post resetRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 400
          expect(body)            .to.be.equal expectedBody
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 200 and reset password when token and user are valid', (done) ->

    email               = generateRandomEmail()
    token               = generateRandomString()
    username            = generateRandomUsername()
    certificate         = null
    expiryPeriod        = ResetHandlerHelper.defaultExpiryPeriod
    passwordBeforeReset = null

    resetRequestParams = generateResetRequestParams
      body            :
        password      : generateRandomString()
        recoveryToken : token

    registerRequestParams = generateRegisterRequestParams
      body       :
        email    : email
        username : username

    queue = [

      ->
        # generating a new certificate and saving it
        certificate = new JPasswordRecovery
          email        : email
          token        : token
          status       : 'active'
          username     : username
          expiryPeriod : expiryPeriod

        certificate.save (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # keeping user's password to compare after reset request
        JUser.one { username }, (err, user) ->
          expect(err).to.not.exist
          passwordBeforeReset = user.password
          queue.next()

      ->
        # expecting reset request to succeed
        request.post resetRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting user's password not to be changed after reset request
        JUser.one { username }, (err, user) ->
          expect(err)           .to.not.exist
          expect(user.password) .to.not.be.equal passwordBeforeReset
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 200 and invalidate other tokens after resetting', (done) ->

    email               = generateRandomEmail()
    token1              = generateRandomString()
    token2              = generateRandomString()
    username            = generateRandomUsername()
    certificate1        = null
    certificate2        = null
    expiryPeriod        = ResetHandlerHelper.defaultExpiryPeriod

    resetRequestParams = generateResetRequestParams
      body            :
        password      : generateRandomString()
        recoveryToken : token1

    registerRequestParams = generateRegisterRequestParams
      body              :
        email           : email
        username        : username

    queue = [

      ->
        # generating a new certificate and saving it
        certificate1 = new JPasswordRecovery
          email        : email
          token        : token1
          status       : 'active'
          username     : username
          expiryPeriod : expiryPeriod

        certificate1.save (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        #generating another certificate which will be checked if invalidated
        certificate2 = new JPasswordRecovery
          email        : email
          token        : token2
          status       : 'active'
          username     : username
          expiryPeriod : expiryPeriod

        certificate2.save (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting reset request to succeed
        request.post resetRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting other token's status be updated as 'invalidated'
        JPasswordRecovery.one { token : token2 }, (err, certificate) ->
          expect(err)                 .to.not.exist
          expect(certificate?.status)  .to.be.equal 'invalidated'
          queue.next()

      -> done()

    ]

    daisy queue


runTests()

