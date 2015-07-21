Bongo                                     = require 'bongo'
koding                                    = require './../bongo'
request                                   = require 'request'
Speakeasy                                 = require 'speakeasy'

{ daisy }                                 = Bongo
{ expect }                                = require 'chai'
{ generateRandomEmail
  generateRandomString
  generateRandomUsername

  LoginHandlerHelper
  RegisterHandlerHelper }                 = require '../../../testhelper'

{ generateLoginRequestParams }            = LoginHandlerHelper
{ generateRegisterRequestParams }         = RegisterHandlerHelper

JLog                                      = null
JUser                                     = null
JAccount                                  = null
JSession                                  = null


# here we have actual tests
runTests = -> describe 'server.handlers.login', ->

  beforeEach (done) ->

    # including models before each test case, requiring them outside of
    # tests suite is causing undefined errors
    { JLog
      JUser
      JAccount
      JSession } = koding.models

    done()


  it 'should send HTTP 404 if request method is not POST', (done) ->

    loginRequestParams = generateLoginRequestParams()

    queue       = []
    methods     = ['put', 'patch', 'delete']

    addRequestToQueue = (queue, method) -> queue.push ->
      loginRequestParams.method = method
      request loginRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 404
        queue.next()

    for method in methods
      addRequestToQueue queue, method

    queue.push -> done()

    daisy queue


  it 'should send HTTP 403 if username is empty', (done) ->

    loginRequestParams = generateLoginRequestParams
      body        :
        username  : ''

    request.post loginRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 403
      expect(body)            .to.be.equal 'Unknown user name'
      done()


  it 'should send HTTP 403 if username exists but password is empty', (done) ->

    email     = generateRandomEmail()
    username  = generateRandomUsername()

    queue = [

      ->
        # registering a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            email    : email
            username : username

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting login to fail when password is empty
        loginRequestParams = generateLoginRequestParams
          body        :
            username  : username
            password  : ''

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 403
          expect(body)            .to.be.equal 'Access denied!'
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 403 if password status is "needs reset"', (done) ->

    username  = generateRandomUsername()
    password  = 'testpass'

    queue = [

      ->
        # registering a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            username : username
            password : password

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # updating user passwordStatus as needs reset
        options = { $set: passwordStatus: 'needs reset' }
        JUser.update { username }, options, (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting login attempt to fail when passwordStatus is 'needs reset'
        loginRequestParams = generateLoginRequestParams
          body        :
            email     : ''
            username  : username
            password  : password

        expectedBody = 'You should reset your password in order to continue!'
        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 403
          expect(body)            .to.be.equal expectedBody
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 403 if 2fa is activated but 2fa code is not provided', (done) ->

    username  = generateRandomUsername()
    password  = 'testpass'

    queue = [

      ->
        # registering a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            username : username
            password : password

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # setting two factor authentication on by adding twofactorkey field
        JUser.update { username }, { $set: twofactorkey: 'somekey' }, (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting login attempt to fail when 2fa code is empty
        loginRequestParams = generateLoginRequestParams
          body        :
            email     : ''
            tfcode    : ''
            username  : username
            password  : password

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 403
          expect(body)            .to.be.equal 'TwoFactor auth Enabled'
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 403 if 2fa is activated and 2fa code is invalid', (done) ->

    username  = generateRandomUsername()
    password  = 'testpass'

    queue = [

      ->
        # registering a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            username : username
            password : password

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # setting two factor authentication on by adding twofactorkey field
        JUser.update { username }, { $set: twofactorkey: 'somekey' }, (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting login attempt to fail when 2fa code is invalid
        loginRequestParams = generateLoginRequestParams
          body        :
            email     : ''
            tfcode    : 'someInvalidCode'
            username  : username
            password  : password

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 403
          expect(body)            .to.be.equal 'Access denied!'
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 200 if two factor authentication code is correct', (done) ->

    username   = generateRandomUsername()
    password   = 'testpass'
    validtfKey = null

    queue = [

      ->
        # registering a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            username : username
            password : password

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # setting two factor authentication on by adding twofactorkey field
        JUser.update { username }, { $set: twofactorkey: 'somekey' }, (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # trying to login with empty tf code
        loginRequestParams = generateLoginRequestParams
          body        :
            tfcode    : ''
            username  : username
            password  : password

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 403
          expect(body)            .to.be.equal 'TwoFactor auth Enabled'
          queue.next()

      ->
        # trying to login with invalid tfcode
        loginRequestParams = generateLoginRequestParams
          body        :
            tfcode    : 'someInvalidCode'
            username  : username
            password  : password

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 403
          expect(body)            .to.be.equal 'Access denied!'
          queue.next()

      ->
        # generating a 2fa key and saving it in mongo
        { base32 : tfcode } = Speakeasy.generate_key
          length    : 20
          encoding  : 'base32'

        validtfKey = tfcode

        JUser.update { username }, { $set: twofactorkey: tfcode }, (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # generating a verificationCode and expecting a successful login
        verificationCode = Speakeasy.totp
          key       : validtfKey
          encoding  : 'base32'

        loginRequestParams = generateLoginRequestParams
          body        :
            tfcode    : verificationCode
            username  : username
            password  : password

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          expect(body)            .to.be.equal ''
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 403 if invitation token is invalid', (done) ->

    username  = generateRandomUsername()
    password  = 'testpass'

    queue = [

      ->
        # registering a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            username : username
            password : password

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting login attempt to fail when invitation token is invalid
        loginRequestParams = generateLoginRequestParams
          body        :
            email     : ''
            token     : 'someInvalidToken'
            username  : username
            password  : password

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 403
          expect(body)            .to.be.equal 'invitation is not valid'
          queue.next()

      -> done()

    ]

    daisy queue



  it 'should send HTTP 403 if groupname is invalid', (done) ->

    username  = generateRandomUsername()
    password  = 'testpass'
    groupName = generateRandomString()

    queue = [

      ->
        # registering a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            username : username
            password : password

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting login attempt to fail when groupName is invalid
        loginRequestParams = generateLoginRequestParams
          body        :
            email     : ''
            username  : username
            password  : password
            groupName : 'someInvalidGroupName'

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 403
          expect(body)            .to.be.equal 'group doesnt exist'
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 403 if there is brute force attack', (done) ->

    queue                  = []
    username               = generateRandomUsername()
    password               = 'testpass'

    loginRequestParams = generateLoginRequestParams
      body        :
        username  : username
        password  : 'someInvalidPassword'

    addRemoveUserLogsToQueue = (queue, username) ->
      queue.push ->
        JLog.remove { username }, (err) ->
          expect(err).to.not.exist
          queue.next()

    addLoginTrialToQueue = (queue, tryCount) ->
      queue.push ->

        expectedBody = switch
          when tryCount < JLog.tryLimit()
            'Access denied!'
          else
            "Your login access is blocked for
            #{JLog.timeLimit()} minutes."

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 403
          expect(body)            .to.be.equal expectedBody
          queue.next()

    queue.push ->
      # registering a new user
      registerRequestParams = generateRegisterRequestParams
        body       :
          username : username
          password : password

      request.post registerRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 200
        queue.next()

    # removing logs for a fresh start
    addRemoveUserLogsToQueue queue, username

    # this loop adds try_limit + 1 trials to queue
    for i in [0..JLog.tryLimit()]
      addLoginTrialToQueue queue, i

    # removing logs for this username after test passes
    addRemoveUserLogsToQueue queue, username

    queue.push -> done()

    daisy queue


  it 'should send HTTP 403 if account was not found', (done) ->

    username  = generateRandomUsername()
    password  = 'testpass'

    queue = [

      ->
        # registering a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            username : username
            password : password

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # deleting account of newly registered user
        JAccount.remove { "profile.nickname": username }, (err)->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting login to fail after deleting account
        loginRequestParams = generateLoginRequestParams
          body        :
            username  : username
            password  : password

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 403
          expect(body)            .to.be.equal 'No account found!'
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 403 if user is blocked', (done) ->

    user     = null
    username = generateRandomUsername()
    password = 'testpass'

    loginRequestParams = generateLoginRequestParams
      body        :
        username  : username
        password  : password

    queue = [

      ->
        # registering a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            username : username
            password : password

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting successful login
        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          expect(body)            .to.be.equal ''
          queue.next()

      ->
        # fetching user record
        JUser.one { username }, (err, user_) ->
          expect(err).to.not.exist
          user = user_
          queue.next()

      ->
        # blocking user for 1 day
        untilDate = new Date(Date.now() + 1000 * 60 * 60 * 24)
        user.block untilDate, (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting login attempt to fail and return blocked message
        toDate        = user.blockedUntil.toUTCString()
        expectedBody  = JUser.getBlockedMessage toDate

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 403
          expect(body)            .to.be.equal expectedBody
          queue.next()

      ->
        # unblocking user
        user.unblock (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting user to be able to login
        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          expect(body)            .to.be.equal ''
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 200 and normalizeLoginId if user exists', (done) ->

    email     = generateRandomEmail()
    username  = generateRandomUsername()
    password  = 'testpass'

    queue = [

      ->
        # registering a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            email    : email
            username : username
            password : password

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting successful login with newly registered username
        loginRequestParams = generateLoginRequestParams
          body        :
            username  : username
            password  : password

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          expect(body)            .to.be.equal ''
          queue.next()

      ->
        # expecting successful login with newly registered email
        loginRequestParams = generateLoginRequestParams
          body        :
            username  : email
            password  : password

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          expect(body)            .to.be.equal ''
          queue.next()

      -> done()

    ]

    daisy queue


  # session is being craeted by jsession.fetchSession if does not exist
  it 'should send HTTP 200 even if session does not exist', (done) ->

    username  = generateRandomUsername()
    password  = 'testpass'

    queue = [

      ->
        # registering a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            username : username
            password : password

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # removing session
        JSession.remove { username }, (err) ->
          expect(err).to.not.exist
          queue.next()

      ->
        # expecting successful login even if the session was removed
        loginRequestParams = generateLoginRequestParams
          body        :
            email     : ''
            username  : username
            password  : password

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          expect(body)            .to.be.equal ''
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 200 if data is valid and update user and session data', (done) ->

    email                  = generateRandomEmail()
    username               = generateRandomUsername()
    password               = 'testpass'
    juserLastLoginDate     = null
    jsessionLastAccess     = null

    queue = [

      ->
        # registering a new user
        registerRequestParams = generateRegisterRequestParams
          body       :
            email    : email
            username : username
            password : password

        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # keeping juser last login date
        JUser.one { username }, (err, user) ->
          expect(err).to.not.exist
          juserLastLoginDate = user.lastLoginDate
          queue.next()

      ->
        # keeping jsession last access
        JSession.one { username }, (err, session) ->
          expect(err).to.not.exist
          jsessionLastAccess = session.lastAccess
          queue.next()

      ->
        # expecting successful login with newly registered username
        loginRequestParams = generateLoginRequestParams
          body        :
            username  : username
            password  : password

        request.post loginRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          expect(body)            .to.be.equal ''
          queue.next()

      ->
        # expecting juser last login date not to be same after login
        JUser.one { username }, (err, user) ->
          expect(err)           .to.not.exist
          expect(juserLastLoginDate) .not.to.be.equal user.lastLoginDate
          queue.next()

      ->
        # expecting jsession last login date not to be same after login
        JSession.one { username }, (err, session) ->
          expect(err)                .to.not.exist
          expect(jsessionLastAccess) .not.to.be.equal session.lastAccess
          queue.next()

      -> done()

    ]

    daisy queue




runTests()

