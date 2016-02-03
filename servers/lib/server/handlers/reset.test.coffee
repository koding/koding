{ async
  expect
  request
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity }        = require '../../../testhelper'
{ testCsrfToken }                 = require '../../../testhelper/handler'
{ defaultExpiryPeriod
  generateResetRequestParams }    = require '../../../testhelper/handler/resethelper'
{ generateRegisterRequestParams } = require '../../../testhelper/handler/registerhelper'

JUser             = require '../../../models/user'
JPasswordRecovery = require '../../../models/passwordrecovery'


beforeTests = before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'server.handlers.reset', ->

  it 'should fail when csrf token is invalid', (done) ->

    testCsrfToken generateResetRequestParams, 'post', done


  it 'should send HTTP 404 if request method is not POST', (done) ->

    resetRequestParams = generateResetRequestParams()

    queue   = []
    methods = ['put', 'patch', 'delete']

    addRequestToQueue = (queue, method) -> queue.push (next) ->
      resetRequestParams.method = method
      request resetRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 404
        next()

    for method in methods
      addRequestToQueue queue, method

    async.series queue, done


  it 'should send HTTP 400 if token is not set', (done) ->

    resetRequestParams = generateResetRequestParams
      body            :
        password      : generateRandomString()
        recoveryToken : ''

    request.post resetRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'Invalid token!'
      done()


  it 'should send HTTP 400 if password is not set', (done) ->

    resetRequestParams = generateResetRequestParams
      body            :
        password      : ''
        recoveryToken : generateRandomString()

    request.post resetRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'Invalid password!'
      done()


  it 'should send HTTP 400 if token is not found', (done) ->

    resetRequestParams = generateResetRequestParams
      body            :
        password      : generateRandomString()
        recoveryToken : generateRandomString()

    request.post resetRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'Invalid token.'
      done()


  it 'should send HTTP 400 if token is not active', (done) ->

    email        = generateRandomEmail()
    token        = generateRandomString()
    username     = generateRandomUsername()
    certificate  = null
    expiryPeriod = defaultExpiryPeriod
    expectedBody = 'This password recovery certificate cannot be redeemed.'

    resetRequestParams = generateResetRequestParams
      body            :
        password      : generateRandomString()
        recoveryToken : token

    queue = [

      (next) ->
        # generating a new certificate and saving it
        certificate = new JPasswordRecovery
          email        : email
          token        : token
          status       : 'active'
          username     : username
          expiryPeriod : expiryPeriod

        certificate.save (err) ->
          expect(err).to.not.exist
          next()

      (next) ->
        # redeeming certificate without before reset request
        certificate.redeem (err) ->
          expect(err).to.not.exist
          next()

      (next) ->
        # expecting failure because certificate status is redeemed
        request.post resetRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 400
          expect(body).to.be.equal expectedBody
          next()

      (next) ->
        # expiring certificate before reset request
        certificate.expire (err) ->
          expect(err).to.not.exist
          next()

      (next) ->
        # expecting failure because certificate status is expired
        request.post resetRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 400
          expect(body).to.be.equal expectedBody
          next()

    ]

    async.series queue, done


  it 'should send HTTP 400 if token is valid but user doesnt exist', (done) ->

    email        = generateRandomEmail()
    token        = generateRandomString()
    username     = generateRandomUsername()
    certificate  = null
    expiryPeriod = defaultExpiryPeriod

    resetRequestParams = generateResetRequestParams
      body            :
        password      : generateRandomString()
        recoveryToken : token

    queue = [

      (next) ->
        # generating a new certificate and saving it
        certificate = new JPasswordRecovery
          email        : email
          token        : token
          status       : 'active'
          username     : username
          expiryPeriod : expiryPeriod

        certificate.save (err) ->
          expect(err).to.not.exist
          next()

      (next) ->
        # expecting failure because user doesn't exist
        expectedBody = 'Unknown user!'
        request.post resetRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 400
          expect(body).to.be.equal expectedBody
          next()

    ]

    async.series queue, done


  it 'should send HTTP 200 and reset password when token and user are valid', (done) ->

    email               = generateRandomEmail()
    token               = generateRandomString()
    username            = generateRandomUsername()
    certificate         = null
    expiryPeriod        = defaultExpiryPeriod
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

      (next) ->
        # generating a new certificate and saving it
        certificate = new JPasswordRecovery
          email        : email
          token        : token
          status       : 'active'
          username     : username
          expiryPeriod : expiryPeriod

        certificate.save (err) ->
          expect(err).to.not.exist
          next()

      (next) ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          next()

      (next) ->
        # keeping user's password to compare after reset request
        JUser.one { username }, (err, user) ->
          expect(err).to.not.exist
          passwordBeforeReset = user.password
          next()

      (next) ->
        # expecting reset request to succeed
        request.post resetRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          next()

      (next) ->
        # expecting user's password not to be changed after reset request
        JUser.one { username }, (err, user) ->
          expect(err).to.not.exist
          expect(user.password).to.not.be.equal passwordBeforeReset
          next()

    ]

    async.series queue, done


  it 'should send HTTP 200 and invalidate other tokens after resetting', (done) ->

    email               = generateRandomEmail()
    token1              = generateRandomString()
    token2              = generateRandomString()
    username            = generateRandomUsername()
    certificate1        = null
    certificate2        = null
    expiryPeriod        = defaultExpiryPeriod

    resetRequestParams = generateResetRequestParams
      body            :
        password      : generateRandomString()
        recoveryToken : token1

    registerRequestParams = generateRegisterRequestParams
      body              :
        email           : email
        username        : username

    queue = [

      (next) ->
        # generating a new certificate and saving it
        certificate1 = new JPasswordRecovery
          email        : email
          token        : token1
          status       : 'active'
          username     : username
          expiryPeriod : expiryPeriod

        certificate1.save (err) ->
          expect(err).to.not.exist
          next()

      (next) ->
        #generating another certificate which will be checked if invalidated
        certificate2 = new JPasswordRecovery
          email        : email
          token        : token2
          status       : 'active'
          username     : username
          expiryPeriod : expiryPeriod

        certificate2.save (err) ->
          expect(err).to.not.exist
          next()

      (next) ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          next()

      (next) ->
        # expecting reset request to succeed
        request.post resetRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          next()

      (next) ->
        # expecting other token's status be updated as 'invalidated'
        JPasswordRecovery.one { token : token2 }, (err, certificate) ->
          expect(err).to.not.exist
          expect(certificate?.status).to.be.equal 'invalidated'
          next()

    ]

    async.series queue, done


runTests()
