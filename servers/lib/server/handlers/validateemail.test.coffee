{ async
  expect
  request
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity }             = require '../../../testhelper'
{ generateRegisterRequestParams }      = require '../../../testhelper/handler/registerhelper'
{ generateValidateEmailRequestParams } = require '../../../testhelper/handler/validateemailhelper'

JUser = require '../../../models/user'


beforeTests = -> before (done) ->

  checkBongoConnectivity done


# here we have actual tests
runTests = -> describe 'server.handlers.validateemail', ->

  it 'should send HTTP 404 if request method is not POST', (done) ->

    validateEmailRequestParams = generateValidateEmailRequestParams
      body    :
        email : generateRandomEmail()

    queue   = []
    methods = ['put', 'patch', 'delete']

    addRequestToQueue = (queue, method) -> queue.push (next) ->
      validateEmailRequestParams.method = method
      request validateEmailRequestParams, (err, res, body) ->
        expect(err).to.not.exist
        expect(res.statusCode).to.be.equal 404
        next()

    for method in methods
      addRequestToQueue queue, method

    async.series queue, done


  it 'should send HTTP 400 if email is not set', (done) ->

    validateEmailRequestParams      = generateValidateEmailRequestParams()
    validateEmailRequestParams.body = null

    request.post validateEmailRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'Bad request'
      done()


  it 'should send HTTP 400 if email is not valid', (done) ->

    validateEmailRequestParams = generateValidateEmailRequestParams
      body    :
        email : 'someInvalidEmail'

    request.post validateEmailRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'Bad request'
      done()


  # TODO: returning 'Bad request' error message instead of 'email is in use'
  it 'should send HTTP 400 if email is in use', (done) ->

    email     = generateRandomEmail()
    username  = generateRandomUsername()

    registerRequestParams = generateRegisterRequestParams
      body    :
        email : email

    validateEmailRequestParams = generateValidateEmailRequestParams
      body    :
        email : email

    queue = [

      (next) ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          next()

      (next) ->
        # expecting email validation to fail using already registered email
        request.post validateEmailRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 400
          expect(body).to.be.equal 'Bad request'
          next()

    ]

    async.series queue, done


  it 'should send HTTP 400 if dotted gmail address is in use', (done) ->

    email    = generateRandomEmail 'gmail.com'
    username = generateRandomUsername()

    registerRequestParams = generateRegisterRequestParams
      body    :
        email : email

    [username, host] = email.split '@'

    username  = username.replace /(.)/g, '$1.'
    candidate = "#{username}@#{host}"

    validateEmailRequestParams = generateValidateEmailRequestParams
      body    :
        email : candidate

    # expecting email validation to fail using already registered email
    request.post validateEmailRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 400
      expect(body).to.be.equal 'Email is taken!'
      done()


  it 'should send HTTP 400 if email is in use and password is invalid', (done) ->

    email    = generateRandomEmail()
    username = generateRandomUsername()
    password = 'testpass'

    registerRequestParams = generateRegisterRequestParams
      body              :
        email           : email
        username        : username
        password        : password
        passwordConfirm : password

    validateEmailRequestParams = generateValidateEmailRequestParams
      body       :
        email    : email
        password : 'someInvalidPassword'

    queue = [

      (next) ->
        request.post registerRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          next()

      (next) ->
        request.post validateEmailRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 400
          expect(body).to.be.equal 'Bad request'
          next()

    ]

    async.series queue, done


  it 'should send HTTP 400 if 2FA was activated for the account', (done) ->

    email     = generateRandomEmail()
    username  = generateRandomUsername()
    password  = 'testpass'

    registerRequestParams = generateRegisterRequestParams
      body              :
        email           : email
        username        : username
        password        : password
        passwordConfirm : password

    validateEmailRequestParams = generateValidateEmailRequestParams
      body       :
        email    : email
        password : password

    queue = [

      (next) ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          expect(body).to.be.equal ''
          next()

      (next) ->
        # setting two factor authentication on by adding twofactorkey field
        JUser.update { username }, { $set: { twofactorkey: 'somekey' } }, (err) ->
          expect(err).to.not.exist
          next()

      (next) ->
        # expecting 400 for the 2fa enabled account
        request.post validateEmailRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 400
          expect(body).to.be.equal 'TwoFactor auth Enabled'
          next()

    ]

    async.series queue, done


  it 'should send HTTP 200 if email is in use and password is valid', (done) ->

    email     = generateRandomEmail()
    username  = generateRandomUsername()
    password  = 'testpass'

    registerRequestParams = generateRegisterRequestParams
      body              :
        email           : email
        username        : username
        password        : password
        passwordConfirm : password

    validateEmailRequestParams = generateValidateEmailRequestParams
      body       :
        email    : email
        password : password

    queue = [

      (next) ->
        # registering new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          next()

      (next) ->
        # expecting email with invalid password to fail
        request.post validateEmailRequestParams, (err, res, body) ->
          expect(err).to.not.exist
          expect(res.statusCode).to.be.equal 200
          expect(body).to.be.equal 'User is logged in!'
          next()

    ]

    async.series queue, done


  it 'should send HTTP 200 if email is valid and not in use', (done) ->

    cookieJar = request.jar()

    validateEmailRequestParams = generateValidateEmailRequestParams
      jar     : cookieJar
      body    :
        email : generateRandomEmail()

    url = validateEmailRequestParams.url

    request.post validateEmailRequestParams, (err, res, body) ->
      expect(err).to.not.exist
      expect(res.statusCode).to.be.equal 200
      # expecting clientId cookie to be set
      expect(cookieJar.getCookieString url).to.contain 'clientId'
      expect(body).to.be.equal 'true'
      done()


beforeTests()

runTests()
