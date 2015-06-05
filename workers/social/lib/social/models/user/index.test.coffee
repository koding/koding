{ argv }                  = require 'optimist'
{ expect }                = require "chai"
{ env : {MONGO_URL} }     = process

KONFIG                    = require('koding-config-manager').load("main.#{argv.c}")

JLog                      = require '../log/index'
Bongo                     = require 'bongo'
JUser                     = require './index'
mongo                     = MONGO_URL or "mongodb://#{ KONFIG.mongo }"
JAccount                  = require '../account'
JSession                  = require '../session'
TestHelper                = require '../../../../testhelper'

{ daisy }                 = Bongo
{ getCredentials,
  getRandomString,
  getDummyClientData,
  getDummyUserFormData }  = TestHelper

###
  variables
###
bongo                       = null
client                      = {}
session                     = null
account                     = null
clientId                    = null
credentials                 = {}
dummyClient                 = {}
userFormData                = {}
dummyUserFormData           = {}


# this function will be called once before running any test
beforeTests = -> before (done) ->

  # getting dummy data
  credentials       = getCredentials()
  dummyClient       = getDummyClientData()
  dummyUserFormData = getDummyUserFormData()

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

    # resetting credentials before each test case
    beforeEach ->

      credentials = getCredentials()


    it 'should be to login user when data is valid', (done) ->

      JUser.login clientId, credentials, (err) ->
        expect(err).to.not.exist
        done()


    it 'should pass error if user\'s password needs reset', (done) ->

      username = password = 'kodingtester'
      credentials.username = credentials.password = 'kodingtester'

      setUserPasswordStatus = (status) ->
        JUser.update { username }, {$set: passwordStatus: status}, (err) ->
          expect(err).to.not.exist
          queue.next()

      queue = [

        ->
          setUserPasswordStatus 'valid'

        ->
          JUser.login clientId, credentials, (err)->
            expect(err).to.not.exist
            queue.next()

        ->
          setUserPasswordStatus 'needs reset'

        ->
          JUser.login clientId, credentials, (err)->
            expect(err).to.exist
            queue.next()

        ->
          setUserPasswordStatus 'valid'

        -> done()

      ]

      daisy queue


    it 'should create a new session if clientId is not specified', (done) ->

      JUser.login null, credentials, (err) ->
        expect(err).to.not.exist
        done()


    it 'should should pass error if username is not registered', (done) ->

      credentials.username = 'herecomesanunregisteredusername'
      JUser.login clientId, credentials, (err) ->
        expect(err).to.exist
        done()


    # this case also tests if logging is working correctly
    it 'should check for brute force attack', (done) ->

      queue                   = []
      credentials.username    = 'kodingtester'
      credentials.password    = 'someinvalidpassword'
      TRY_LIMIT_FOR_BLOCKING  = JLog.tryLimit()
      TIME_LIMIT_FOR_BLOCKING = JLog.timeLimit()

      removeUserLogs = ->
        JLog.remove { username : credentials.username }, (err) ->
          queue.next()

      addLoginTrialToQueue = (queue, tryCount) ->
        queue.push ->
          JUser.login clientId, credentials, (err) ->
            expectedError = switch
              when tryCount < TRY_LIMIT_FOR_BLOCKING
                'Access denied!'
              else
                "Your login access is blocked for
                #{TIME_LIMIT_FOR_BLOCKING} minutes."

            expect(err.message).to.be.equal expectedError
            queue.next()

      # removing logs for a fresh start
      queue.push removeUserLogs

      # this loop adds try_limit + 1 trials to queue
      for i in [0..TRY_LIMIT_FOR_BLOCKING]
        addLoginTrialToQueue queue, i

      # removing logs for this username after test passes
      queue.push removeUserLogs

      queue.push -> done()

      daisy queue


    it 'should pass error if invitationToken is set but not valid', (done) ->

      credentials.invitationToken = 'someinvalidtoken'

      JUser.login clientId, credentials, (err) ->
        expect(err).to.exist
        done()

    it 'should pass error if groupName is not valid', (done) ->

      credentials.groupName = 'someinvalidgroupName'

      JUser.login clientId, credentials, (err) ->
        expect(err).to.exist
        done()


  describe '#convert()', ->
      
    # this function will be called everytime before each test case under this test suite
    beforeEach ->
      
      # cloning the client and userFormData from dummy datas each time.
      # used pure nodejs instead of a library bcs we need deep cloning here.
      client                = JSON.parse JSON.stringify dummyClient
      userFormData          = JSON.parse JSON.stringify dummyUserFormData

      randomString          = getRandomString()
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

    
        
