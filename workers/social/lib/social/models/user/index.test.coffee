{ argv }                      = require 'optimist'
{ expect }                    = require "chai"
{ env : {MONGO_URL} }         = process

KONFIG                        = require('koding-config-manager').load("main.#{argv.c}")

JLog                          = require '../log/index'
Bongo                         = require 'bongo'
JUser                         = require './index'
mongo                         = MONGO_URL or "mongodb://#{ KONFIG.mongo }"
JAccount                      = require '../account'
JSession                      = require '../session'
Speakeasy                     = require 'speakeasy'
TestHelper                    = require '../../../../testhelper'

{ daisy }                     = Bongo
{ generateUserInfo
  generateCredentials,
  generateRandomString,
  generateDummyClientData,
  generateDummyUserFormData } = TestHelper


###
  variables
###
bongo             = null
clientId          = null
dummyClient       = null
dummyUserFormData = null


# this function will be called once before running any test
beforeTests = -> before (done) ->

  # generating dummy data
  dummyClient       = generateDummyClientData()
  dummyUserFormData = generateDummyUserFormData()

  bongo = new Bongo
    root   : __dirname
    mongo  : mongo
    models : '../../models'
    
  bongo.once 'dbClientReady', ->
    
    # creating a session before running tests
    JSession.createSession (err, { session, account }) ->
      clientId                  = session.clientId
      dummyClient.sessionToken  = session.token
      done()
      
      
# this function will be called after all tests are executed
afterTests = -> after ->
  

# here we have actual tests
runTests = -> describe 'workers.social.user.index', ->
  
  it 'should be able to make mongodb connection', (done) ->

    { serverConfig : { _serverState } } = bongo.getClient()
    expect(_serverState).to.be.equal 'connected'
    done()


  describe '#login()', ->

    it 'should be to able login user when data is valid', (done) ->

      session           = null
      lastLoginDate     = null
      # generating user info with random username and password
      { username, password }    = userInfo = generateUserInfo()
      loginCredentials          = generateCredentials { username, password }

      queue = [

        ->
          # creating a new user
          JUser.createUser userInfo, (err, user) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # expecting successful login
          JSession.one { clientId }, (err, session) ->
            expect(err)      .to.not.exist
            expect(session)  .to.exist
            queue.next()

        ->
          JUser.one { username : loginCredentials.username }, (err, user) ->
            expect(err).to.not.exist
            lastLoginDate = user.lastLoginDate
            queue.next()

        ->
          JUser.login clientId, loginCredentials, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # expecting login date to be saved successfully
          JUser.one { username : loginCredentials.username }, (err, user) ->
            expect(err)           .to.not.exist
            expect(lastLoginDate) .not.to.be.equal user.lastLoginDate
            queue.next()

        -> done()

      ]

      daisy queue


    it 'should handle two factor authentication correctly', (done) ->

      tfcode                    = null
      # generating user info with random username and password
      { username, password }    = userInfo = generateUserInfo()
      loginCredentials          = generateCredentials { username, password }

      queue = [

        ->
          # creating a new user
          JUser.createUser userInfo, (err, user) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # setting two factor authentication on by adding twofactorkey field
          JUser.update { username }, { $set: twofactorkey: 'somekey' }, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # trying to login with empty tf code
          loginCredentials.tfcode = ''
          JUser.login clientId, loginCredentials, (err) ->
            expect(err.message).to.be.equal 'TwoFactor auth Enabled'
            queue.next()

        ->
          # trying to login with invalid tfcode
          loginCredentials.tfcode = 'invalidtfcode'
          JUser.login clientId, loginCredentials, (err) ->
            expect(err.message).to.be.equal 'Access denied!'
            queue.next()

        ->
          # generating a 2fa key and saving it in mongo
          { base32 : tfcode } = Speakeasy.generate_key
            length    : 20
            encoding  : 'base32'
          JUser.update { username }, { $set: twofactorkey: tfcode }, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # generating a verificationCode and expecting a successful login
          verificationCode = Speakeasy.totp
            key       : tfcode
            encoding  : 'base32'
          loginCredentials.tfcode = verificationCode
          JUser.login clientId, loginCredentials, (err) ->
            expect(err).to.not.exist
            queue.next()

        -> done()

      ]

      daisy queue


    it 'should handle groups correctly', (done) ->

      loginCredentials            = generateCredentials()
      loginCredentials.groupName  = 'invalidgroupName'

      queue = [

        ->
          JUser.login clientId, loginCredentials, (err)->
            expect(err.message).to.be.equal 'group doesnt exist'
            queue.next()

        -> done()

      ]

      daisy queue


    it 'should pass error if account is not found', (done) ->

      { username, password }    = userInfo = generateUserInfo()
      loginCredentials          = generateCredentials { username, password }

      queue = [

        ->
          # creating a new user with the newly generated userinfo
          JUser.createUser userInfo, (err, user) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # removing users account
          JAccount.remove { 'profile.nickname': username }, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # expecting not to able to login without an account
          JUser.login clientId, loginCredentials, (err)->
            expect(err.message).to.be.equal "No account found!"
            queue.next()

        -> done()

      ]

      daisy queue


    it 'should check if the user is blocked', (done) ->

      # generating user info with random username and password
      user                      = null
      { username, password }    = userInfo = generateUserInfo()
      loginCredentials          = generateCredentials { username, password }

      queue = [

        ->
          # creating a new user with the newly generated userinfo
          JUser.createUser userInfo, (err, user_) ->
            user = user_
            expect(err).to.not.exist
            queue.next()

        ->
          # expecting successful login with the newly generated user
          JUser.login clientId, loginCredentials, (err)->
            expect(err).to.not.exist
            queue.next()

        ->
          # blocking user for 1 day
          untilDate = new Date(Date.now() + 1000 * 60 * 24)
          user.block untilDate, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # expecting login attempt to fail
          JUser.login clientId, loginCredentials, (err)->
            toDate = user.blockedUntil.toUTCString()
            expect(err.message).to.be.equal JUser.getBlockedMessage toDate
            queue.next()

        ->
          # unblocking user
          user.unblock (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # expecting user to be able to login
          JUser.login clientId, loginCredentials, (err)->
            expect(err).to.not.exist
            queue.next()

        -> done()

      ]

      daisy queue


    it 'should pass error if user\'s password needs reset', (done) ->

      # generating user info with random username and password
      { username, password }    = userInfo = generateUserInfo()
      loginCredentials          = generateCredentials { username, password }

      setUserPasswordStatus = (queue, username, status) ->
        JUser.update { username }, {$set: passwordStatus: status}, (err) ->
          expect(err).to.not.exist
          queue.next()

      queue = [

        ->
          # creating a new user with the newly generated userinfo
          JUser.createUser userInfo, (err, user) ->
            expect(err).to.not.exist
            queue.next()

        ->
          setUserPasswordStatus queue, username, 'valid'

        ->
          JUser.login clientId, loginCredentials, (err)->
            expect(err).to.not.exist
            queue.next()

        ->
          setUserPasswordStatus queue, username, 'needs reset'

        ->
          JUser.login clientId, loginCredentials, (err)->
            expect(err).to.exist
            queue.next()

        ->
          setUserPasswordStatus queue, username, 'valid'

        -> done()

      ]

      daisy queue


    it 'should create a new session if clientId is not specified', (done) ->

      loginCredentials = generateCredentials()

      JUser.login null, loginCredentials, (err) ->
        expect(err).to.not.exist
        done()


    it 'should should pass error if username is not registered', (done) ->

      loginCredentials = generateCredentials
        username : 'herecomesanunregisteredusername'

      JUser.login clientId, loginCredentials, (err) ->
        expect(err.message).to.be.equal 'Unknown user name'
        done()


    # this case also tests if logging is working correctly
    it 'should check for brute force attack', (done) ->

      queue                  = []
      { username, password } = userInfo = generateUserInfo()
      loginCredentials       = generateCredentials
        username : username
        password : 'someInvalidPassword'


      addRemoveUserLogsToQueue = (queue, username) ->
        queue.push ->
          JLog.remove { username }, (err) ->
            expect(err).to.not.exist
            queue.next()

      addLoginTrialToQueue = (queue, tryCount) ->
        queue.push ->
          JUser.login clientId, loginCredentials, (err) ->
            expectedError = switch
              when tryCount < JLog.tryLimit()
                'Access denied!'
              else
                "Your login access is blocked for
                #{JLog.timeLimit()} minutes."

            expect(err.message).to.be.equal expectedError
            queue.next()

      queue.push ->
        # creating a new user with the newly generated userinfo
        JUser.createUser userInfo, (err, user) ->
          expect(err).to.not.exist
          queue.next()

      # removing logs for a fresh start
      addRemoveUserLogsToQueue queue, loginCredentials.username

      # this loop adds try_limit + 1 trials to queue
      for i in [0..JLog.tryLimit()]
        addLoginTrialToQueue queue, i

      # removing logs for this username after test passes
      addRemoveUserLogsToQueue queue, loginCredentials.username

      queue.push -> done()

      daisy queue


    it 'should pass error if invitationToken is set but not valid', (done) ->

      loginCredentials = generateCredentials
        invitationToken : 'someinvalidtoken'

      JUser.login clientId, loginCredentials, (err) ->
        expect(err.message).to.be.equal 'invitation is not valid'
        done()


    it 'should pass error if groupName is not valid', (done) ->

      loginCredentials = generateCredentials
        groupName : 'someinvalidgroupName'

      JUser.login clientId, loginCredentials, (err) ->
        expect(err.message).to.be.equal 'group doesnt exist'
        done()


  describe '#convert()', ->

    # variables that will be used in the convert test suite scope
    client       = {}
    userFormData = {}
      
    # this function will be called everytime before each test case under this test suite
    beforeEach ->
      
      # cloning the client and userFormData from dummy datas each time.
      # used pure nodejs instead of a library bcs we need deep cloning here.
      client                = JSON.parse JSON.stringify dummyClient
      userFormData          = JSON.parse JSON.stringify dummyUserFormData

      randomString          = generateRandomString()
      userFormData.email    = "kodingtestuser+#{randomString}@gmail.com"
      userFormData.username = randomString
      
    
    it 'should pass error if account is already registered', (done) ->
        
      client.connection.delegate.type = 'registered'
      
      JUser.convert client, userFormData, (err) ->
        expect(err)         .to.exist
        expect(err.message) .to.be.equal "This account is already registered."
        done()


    it 'should pass error if username is a reserved one', (done) ->
      
      queue             = []
      reservedUsernames = ['guestuser', 'guest-']
     
      for username in reservedUsernames
        userFormData.username = username
        
        queue.push ->
          JUser.convert client, userFormData, (err) ->
            expect(err.message).to.exist
            queue.next()
      
      # done callback will be called after all usernames checked
      queue.push -> done()
        
      daisy queue
      
  
    it 'should pass error if passwords do not match', (done) ->
      
      userFormData.password         = 'somePassword'
      userFormData.passwordConfirm  = 'anotherPassword'

      JUser.convert client, userFormData, (err) ->
        expect(err)         .to.exist
        expect(err.message) .to.be.equal "Passwords must match!"
        done()
      
      
    it 'should pass error if username is in use', (done) ->
      
      queue = [
        
        ->
          JUser.convert client, userFormData, (err) ->
            expect(err).to.not.exist
            queue.next()
        
        ->
          # sending a different email address, username will remain same(duplicate)
          userFormData.email = 'kodingtestuser@koding.com'

          JUser.convert client, userFormData, (err) ->
            expect(err.message).to.exist
            queue.next()
        
        -> done()

      ]
    
      daisy queue

    
    it 'should pass error if email is in use', (done) ->
      
      queue = [

        ->
          JUser.convert client, userFormData, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          # sending a different username, email address will remain same(duplicate)
          userFormData.username = 'kodingtestuser'

          JUser.convert client, userFormData, (err) ->
            expect(err.message).to.exist
            queue.next()
        
        -> done()

      ]

      daisy queue
    
    
    it.skip 'should set a random password when signed up with github', (done) ->
    

    it 'should register user and create account when valid data passed to convert method', (done) ->
      
      queue = [
        
        ->
          JUser.convert client, userFormData, (err) ->
            expect(err).to.not.exist
            queue.next()

        ->
          params = { username : userFormData.username }
          
          JUser.one params, (err, { data : {email, registeredFrom} }) ->
            expect(err)               .to.not.exist
            expect(email)             .to.be.equal userFormData.email
            expect(registeredFrom.ip) .to.be.equal client.clientIP
            queue.next()

        ->
          params = { 'profile.nickname' : userFormData.username }
          
          JAccount.one params, (err, { data : {profile} }) ->
            expect(err)               .to.not.exist
            expect(profile.nickname)  .to.be.equal userFormData.username
            queue.next()
        
        -> done()

      ]

      daisy queue


beforeTests()

runTests()

afterTests()

    
        
