{ argv }     = require 'optimist'
{ expect }   = require "chai"

KONFIG       = require('koding-config-manager').load("main.#{argv.c}")
mongo        = "mongodb://#{ KONFIG.mongo }"

hat          = require 'hat'
Bongo        = require 'bongo'
JUser        = require './index'
JAccount     = require '../account'
JSession     = require '../session'
TestHelper   = require "../../../../TestHelper"


###
  variables
###
bongo                       = null
client                      = {}
session                     = null
account                     = null
dummyClient                 = {}
uniqueNumber                = 0
userFormData                = {}
dummyUserFormData           = {}


# this function will be called once before running any test
beforeTests = -> before (done) ->
  
  # getting dummy data which will passed to convert as parameter
  dummyClient       = TestHelper.getDummyClientData()
  dummyUserFormData = TestHelper.getDummyUserFormData()

  bongo = new Bongo
    root   : __dirname
    mongo  : mongo
    models : '../../models'
    
  bongo.once 'dbClientReady', ->
    
    # creating a session before running tests
    JSession.createSession (err, { session, account }) ->
      dummyClient.sessionToken = session.token
      done()
      
      
# this function will be called after all tests are executed
afterTests = -> after ->
  

# here we have actual tests
runTests = -> describe 'workers.social.user.index', ->
  
  it 'should be able to make mongodb connection', (done) ->
    
    { serverConfig : {_serverState} } = bongo.getClient()
    expect(_serverState).to.be.equal 'connected'
    done()
    
  
  describe '#convert()', ->
      
    # this function will be called everytime before each test case under this test suite
    beforeEach ->
      
      # cloning the client and userFormData from dummy datas each time.
      # used pure nodejs instead of a library bcs we need deep cloning here.
      client                = JSON.parse JSON.stringify dummyClient
      userFormData          = JSON.parse JSON.stringify dummyUserFormData
      
      # generating a random string length of 25 character
      randomString          = hat().slice(7)
      userFormData.email    = "#{randomString}@gmail.com"
      userFormData.username = randomString
      
    
    it 'should pass error if account is already registered', (done) ->
        
      client.connection.delegate.type = 'registered'
      
      JUser.convert client, userFormData, (err) ->
        expect(err.message).to.be.equal "This account is already registered."
        done()


    it 'should pass error if username is a reserved one', (done) ->
      
      count             = 0
      reservedUsernames = ['guestuser', 'guest-']
     
      for username in reservedUsernames
        userFormData.username = username
        
        JUser.convert client, userFormData, (err) ->
          count++
          expect(err.message).to.be.defined
          # running done callback when all usernames checked
          done()  if count is reservedUsernames.length
      
  
    it 'should pass error if passwords do not match', (done) ->
      
      userFormData.password         = 'somePassword'
      userFormData.passwordConfirm  = 'anotherPassword'

      JUser.convert client, userFormData, (err) ->
        expect(err.message).to.be.equal "Passwords must match!"
        done()
      
      
    it 'should pass error if username is in use', (done) ->
      
      JUser.convert client, userFormData, (err) ->
        expect(err.message).to.be.undefined
        
        # sending unique email address, username will remain same(duplicate)
        userFormData.email = 'uniqueemail0@gmail.com'
        
        JUser.convert client, userFormData, (err) ->
          expect(err.message).not.to.be.defined
          done()
    
    
    it 'should pass error if email is in use', (done) ->
      
      JUser.convert client, userFormData, (err) ->
        expect(err.message).to.be.undefined
        
        # sending unique username, email address will remain same(duplicate)
        userFormData.username = 'uniquename0'
        
        JUser.convert client, userFormData, (err) ->
          expect(err.message).not.to.be.defined
          done()
    
    
    it.skip 'should set a random password when signed up with github', (done) ->
    
    
    it 'should pass error when referred is same as username', (done) ->
      
      userFormData.referrer = userFormData.username
      
      JUser.convert client, userFormData, (err) ->
        expect(err.message).not.to.be.equal "User (#{userFormData.username}) tried to refer themself."
        done()
    

    it 'should register user and create account when valid data passed to convert method', (done) ->
      
      JUser.convert client, userFormData, (err) ->
        expect(err.message).to.be.undefined
        
        params = { username : userFormData.username }
        
        JUser.one params, (err, { data : {email, registeredFrom} }) ->
          expect(err)               .to.be.null
          expect(email)             .to.be.equal userFormData.email
          expect(registeredFrom.ip) .to.be.equal client.clientIP
          
          params = { 'profile.nickname' : userFormData.username }
          
          JAccount.one params, (err, { data : {profile} }) ->
            expect(err)             .to.be.null
            expect(profile.nickname).to.be.equal userFormData.username
            done()


beforeTests()

runTests()

afterTests()

    
        
