JLog      = require '../log/index'
JUser     = require './index'
JName     = require '../name'
JAccount  = require '../account'
JSession  = require '../session'
Speakeasy = require 'speakeasy'

{ async
  expect
  withDummyClient
  generateUserInfo
  withConvertedUser
  generateDummyClient
  generateCredentials
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  checkBongoConnectivity
  generateDummyUserFormData } = require '../../../../testhelper'


# this function will be called once before running any test
beforeTests = -> before (done) ->

  checkBongoConnectivity done


# this function will be called after all tests are executed
afterTests = -> after ->


# here we have actual tests
runTests = -> describe 'workers.social.user.index', ->

  describe '#createUser', ->

    it 'should pass error passwordStatus type is not valid', (done) ->

      userInfo                = generateUserInfo()
      userInfo.passwordStatus = 'some invalid passwordStatus'
      JUser.createUser userInfo, (err) ->
        expect(err.message).to.be.equal 'Errors were encountered during validation.'
        done()


    it 'should error if username is not set', (done) ->

      userInfo          = generateUserInfo()
      userInfo.username = ''
      JUser.createUser userInfo, (err) ->
        expect(err).to.exist
        done()


    it 'should pass error if username is in use', (done) ->

      userInfo = generateUserInfo()

      queue = [

        (next) ->
          JUser.createUser userInfo, (err) ->
            expect(err).to.not.exist
            next()

        (next) ->
          # setting a different email, username will be duplicate
          userInfo.email = generateRandomEmail()
          expectedError  = "The slug #{userInfo.username} is not available."

          JUser.createUser userInfo, (err) ->
            expect(err.message).to.be.equal expectedError
            next()

      ]

      async.series queue, done


    it 'should pass error if email is in use', (done) ->

      userInfo = generateUserInfo()

      queue = [

        (next) ->
          JUser.createUser userInfo, (err) ->
            expect(err).to.not.exist
            next()

        (next) ->
          # setting a different username, email will be duplicate
          userInfo.username = generateRandomString()
          expectedError     = "Sorry, \"#{userInfo.email}\" is already in use!"

          JUser.createUser userInfo, (err) ->
            expect(err.message).to.be.equal expectedError
            next()

      ]

      async.series queue, done


    describe 'when user data is valid', ->

      testCreateUserWithValidData = (userInfo, callback) ->

        queue = [

          (next) ->
            # expecting user to be created
            JUser.createUser userInfo, (err) ->
              expect(err).to.not.exist
              # after the user is created, lower casing username because
              # we expect to see the username to be lower cased in jmodel documents
              userInfo.username = userInfo.username.toLowerCase()
              next()

          (next) ->
            # expecting user to be saved
            params = { username : userInfo.username }
            JUser.one params, (err, user) ->
              expect(err).to.not.exist
              expect(user.username).to.be.equal userInfo.username
              next()

          (next) ->
            # expecting account to be created and saved
            params = { 'profile.nickname' : userInfo.username }
            JAccount.one params, (err, account) ->
              expect(err).to.not.exist
              expect(account).to.exist
              next()

          (next) ->
            # expecting name to be created and saved
            params = { 'name' : userInfo.username }
            JName.one params, (err, name) ->
              expect(err).to.not.exist
              expect(name).to.exist
              next()

        ]

        async.series queue, callback


      it 'should be able to create user with lower case username', (done) ->

        userInfo          = generateUserInfo()
        userInfo.username = userInfo.username.toLowerCase()

        testCreateUserWithValidData userInfo, done


      it 'should be able to create user with upper case username', (done) ->

        userInfo          = generateUserInfo()
        userInfo.username = userInfo.username.toUpperCase()

        testCreateUserWithValidData userInfo, done


      it 'should save email frequencies correctly', (done) ->

        userInfo = generateUserInfo()

        userInfo.emailFrequency =
          global         : off
          daily          : off
          followActions  : off
          privateMessage : off

        testCreateUserWithValidData userInfo, ->
          params = { username : userInfo.username }
          JUser.one params, (err, user) ->
            expect(err).to.not.exist
            expect(user.emailFrequency.global).to.be.false
            expect(user.emailFrequency.daily).to.be.false
            expect(user.emailFrequency.privateMessage).to.be.false
            expect(user.emailFrequency.followActions).to.be.false
            done()


  describe '#login()', ->

    describe 'when request is valid', ->

      testLoginWithValidData = (options, callback) ->

        lastLoginDate = null
        { loginCredentials, username } = options
        username ?= loginCredentials.username

        queue = [

          (next) ->
            # expecting successful login
            JUser.login null, loginCredentials, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            # keeping last login date
            JUser.one { username }, (err, user) ->
              expect(err).to.not.exist
              lastLoginDate = user.lastLoginDate
              next()

          (next) ->
            # expecting another successful login
            JUser.login null, loginCredentials, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            # expecting last login date to be changed
            JUser.one { username }, (err, user) ->
              expect(err)           .to.not.exist
              expect(lastLoginDate) .not.to.be.equal user.lastLoginDate
              next()

        ]

        async.series queue, callback


      it 'should be able to login user with lower case username', (done) ->

        # trying to login with username
        withConvertedUser ({ userFormData : { username, password } }) ->
          loginCredentials = generateCredentials { username, password }
          testLoginWithValidData { loginCredentials }, done


      it 'should be able to login with uppercase username', (done) ->
        # trying to login with username
        withConvertedUser ({ userFormData : { username, password } }) ->
          opts = { username : username.toUpperCase(), password }
          loginCredentials = generateCredentials opts
          testLoginWithValidData { loginCredentials, username }, done


      it 'should handle username normalizing correctly', (done) ->

        # trying to login with email instead of username
        withConvertedUser ({ userFormData : { username, password, email } }) ->
          loginCredentials = generateCredentials { username : email, password }
          testLoginWithValidData { loginCredentials, username }, done


    it 'should handle two factor authentication correctly', (done) ->

      withConvertedUser ({ userFormData : { username, password } }) ->

        tfcode           = null
        loginCredentials = generateCredentials { username, password }

        queue = [

          (next) ->
            # setting two factor authentication on by adding twofactorkey field
            JUser.update { username }, { $set: { twofactorkey: 'somekey' } }, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            # trying to login with empty tf code
            loginCredentials.tfcode = ''
            JUser.login null, loginCredentials, (err) ->
              expect(err.message).to.be.equal 'TwoFactor auth Enabled'
              next()

          (next) ->
            # trying to login with invalid tfcode
            loginCredentials.tfcode = 'invalidtfcode'
            JUser.login null, loginCredentials, (err) ->
              expect(err.message).to.be.equal 'Access denied!'
              next()

          (next) ->
            # generating a 2fa key and saving it in mongo
            { base32 : tfcode } = Speakeasy.generate_key
              length    : 20
              encoding  : 'base32'
            JUser.update { username }, { $set: { twofactorkey: tfcode } }, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            # generating a verificationCode and expecting a successful login
            verificationCode = Speakeasy.totp
              key       : tfcode
              encoding  : 'base32'
            loginCredentials.tfcode = verificationCode
            JUser.login null, loginCredentials, (err) ->
              expect(err).to.not.exist
              next()

        ]

        async.series queue, done


    it 'should pass error if account is not found', (done) ->

      { username, password } = userInfo = generateUserInfo()
      loginCredentials       = generateCredentials { username, password }

      queue = [

        (next) ->
          # creating a new user with the newly generated userinfo
          JUser.createUser userInfo, (err, user) ->
            expect(err).to.not.exist
            next()

        (next) ->
          # removing users account
          JAccount.remove { 'profile.nickname': username }, (err) ->
            expect(err).to.not.exist
            next()

        (next) ->
          # expecting not to able to login without an account
          JUser.login null, loginCredentials, (err) ->
            expect(err.message).to.be.equal 'No account found!'
            next()

      ]

      async.series queue, done


    it 'should check if the user is blocked', (done) ->

      # generating user info with random username and password
      user                      = null
      { username, password }    = userInfo = generateUserInfo()
      loginCredentials          = generateCredentials { username, password }

      queue = [

        (next) ->
          # creating a new user with the newly generated userinfo
          JUser.createUser userInfo, (err, user_) ->
            user = user_
            expect(err).to.not.exist
            next()

        (next) ->
          # expecting successful login with the newly generated user
          JUser.login null, loginCredentials, (err) ->
            expect(err).to.not.exist
            next()

        (next) ->
          # blocking user for 1 day
          untilDate = new Date(Date.now() + 1000 * 60 * 60 * 24)
          user.block untilDate, (err) ->
            expect(err).to.not.exist
            next()

        (next) ->
          # expecting login attempt to fail and return blocked message
          JUser.login null, loginCredentials, (err) ->
            toDate = user.blockedUntil.toUTCString()
            expect(err.message).to.be.equal JUser.getBlockedMessage toDate
            next()

        (next) ->
          # unblocking user
          user.unblock (err) ->
            expect(err).to.not.exist
            next()

        (next) ->
          # expecting user to be able to login
          JUser.login null, loginCredentials, (err) ->
            expect(err).to.not.exist
            next()

      ]

      async.series queue, done


    it 'should pass error if user\'s password needs reset', (done) ->

      # generating user info with random username and password
      { username, password }    = userInfo = generateUserInfo()
      loginCredentials          = generateCredentials { username, password }

      setUserPasswordStatus = (username, status, callback) ->
        JUser.update { username }, { $set: { passwordStatus: status } }, (err) ->
          expect(err).to.not.exist
          callback()

      queue = [

        (next) ->
          # creating a new user with the newly generated userinfo
          JUser.createUser userInfo, (err, user) ->
            expect(err).to.not.exist
            next()

        (next) ->
          setUserPasswordStatus username, 'valid', next

        (next) ->
          # expecting successful login
          JUser.login null, loginCredentials, (err) ->
            expect(err).to.not.exist
            next()

        (next) ->
          setUserPasswordStatus username, 'needs reset', next

        (next) ->
          # expecting unsuccessful login attempt
          JUser.login null, loginCredentials, (err) ->
            expect(err).to.exist
            next()

        (next) ->
          setUserPasswordStatus username, 'valid', next

      ]

      async.series queue, done


    it 'should create a new session if clientId is not specified', (done) ->

      loginCredentials = generateCredentials()

      # when client id is not specified, a new session should be created
      JUser.login null, loginCredentials, (err) ->
        expect(err).to.not.exist
        done()


    it 'should should pass error if username is not registered', (done) ->

      loginCredentials = generateCredentials
        username : 'herecomesanunregisteredusername'

      JUser.login null, loginCredentials, (err) ->
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
        queue.push (next) ->
          JLog.remove { username }, (err) ->
            expect(err).to.not.exist
            next()

      addLoginTrialToQueue = (queue, tryCount) ->
        queue.push (next) ->
          JUser.login null, loginCredentials, (err) ->
            expectedError = switch
              when tryCount < JLog.tryLimit()
                'Access denied!'
              else
                "Your login access is blocked for
                #{JLog.timeLimit()} minutes."

            expect(err.message).to.be.equal expectedError
            next()

      queue.push (next) ->
        # creating a new user with the newly generated userinfo
        JUser.createUser userInfo, (err, user) ->
          expect(err).to.not.exist
          next()

      # removing logs for a fresh start
      addRemoveUserLogsToQueue queue, loginCredentials.username

      # this loop adds try_limit + 1 trials to queue
      for i in [0..JLog.tryLimit()]
        addLoginTrialToQueue queue, i

      # removing logs for this username after test passes
      addRemoveUserLogsToQueue queue, loginCredentials.username

      async.series queue, done


    it 'should pass error if invitationToken is set but not valid', (done) ->

      loginCredentials = generateCredentials
        invitationToken : 'someinvalidtoken'

      JUser.login null, loginCredentials, (err) ->
        expect(err.message).to.be.equal 'invitation is not valid'
        done()


    it 'should pass error if group doesnt exist and groupIsBeingCreated is false', (done) ->

      loginCredentials = generateCredentials
        groupName           : 'someinvalidgroupName'
        groupIsBeingCreated : no

      JUser.login null, loginCredentials, (err) ->
        expect(err.message).to.be.equal 'group doesnt exist'
        done()


    it 'should be able to login if group doesnt exist but groupIsBeingCreated is true', (done) ->

      loginCredentials = generateCredentials
        groupName           : 'someinvalidgroupName'
        groupIsBeingCreated : yes

      JUser.login null, loginCredentials, (err) ->
        expect(err).to.not.exist
        done()


  describe '#convert()', ->

    it 'should pass error if account is already registered', (done) ->

      withDummyClient ({ client }) ->
        userFormData = generateDummyUserFormData()
        client.connection.delegate.type = 'registered'
        JUser.convert client, userFormData, (err) ->
          expect(err)         .to.exist
          expect(err.message) .to.be.equal 'This account is already registered.'
          done()


    it 'should pass error if username is a reserved one', (done) ->

      withDummyClient ({ client }) ->
        queue             = []
        userFormData      = generateDummyUserFormData()
        reservedUsernames = ['guestuser', 'guest-']

        for username in reservedUsernames
          userFormData.username = username

          queue.push (next) ->
            JUser.convert client, userFormData, (err) ->
              expect(err.message).to.exist
              next()

        async.series queue, done


    it 'should pass error if passwords do not match', (done) ->

      withDummyClient ({ client }) ->
        userFormData                  = generateDummyUserFormData()
        userFormData.password         = 'somePassword'
        userFormData.passwordConfirm  = 'anotherPassword'

        JUser.convert client, userFormData, (err) ->
          expect(err)         .to.exist
          expect(err.message) .to.be.equal 'Passwords must match!'
          done()


    it 'should pass error if username is in use', (done) ->

      withDummyClient ({ client }) ->
        userFormData = generateDummyUserFormData()

        queue = [

          (next) ->
            JUser.convert client, userFormData, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            # sending a different email address, username will remain same(duplicate)
            userFormData.email = generateRandomEmail()

            JUser.convert client, userFormData, (err) ->
              expect(err.message).to.be.equal 'Errors were encountered during validation'
              next()

        ]

        async.series queue, done


    it 'should pass error if email is in use', (done) ->

      withDummyClient ({ client }) ->
        userFormData = generateDummyUserFormData()

        queue = [

          (next) ->
            JUser.convert client, userFormData, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            # sending a different username, email address will remain same(duplicate)
            userFormData.username = generateRandomUsername()

            JUser.convert client, userFormData, (err) ->
              expect(err?.message).to.be.equal 'Email is already in use!'
              next()

        ]

        async.series queue, done


    describe 'when user data is valid', ->

      testConvertWithValidData = (client, userFormData, callback) ->

        queue = [

          (next) ->
            JUser.convert client, userFormData, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            params = { username : userFormData.username }

            JUser.one params, (err, { data : { email, registeredFrom } }) ->
              expect(err).to.not.exist
              expect(email).to.be.equal userFormData.email
              expect(registeredFrom.ip).to.be.equal client.clientIP
              next()

          (next) ->
            params = { 'profile.nickname' : userFormData.username }

            JAccount.one params, (err, { data : { profile } }) ->
              expect(err).to.not.exist
              expect(profile.nickname).to.be.equal userFormData.username
              next()

        ]

        async.series queue, callback


      it 'should be able to register user with lower case username', (done) ->

        withDummyClient ({ client }) ->
          userFormData          = generateDummyUserFormData()
          userFormData.username = userFormData.username.toLowerCase()
          testConvertWithValidData client, userFormData, done


      it 'should be able to register user with upper case username', (done) ->

        withDummyClient ({ client }) ->
          userFormData          = generateDummyUserFormData()
          userFormData.username = userFormData.username.toUpperCase()
          testConvertWithValidData client, userFormData, done


  describe '#unregister()', ->

    describe 'when user is not registered', ->

      it 'should return err', (done) ->

        client = {}

        queue = [

          (next) ->
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              next()

          (next) ->
            # username won't matter, only client's account will be checked
            JUser.unregister client, generateRandomUsername(), (err) ->
              expect(err?.message).to.be.equal 'You are not registered!'
              next()

        ]

        async.series queue, done


    describe 'when user is registered', ->

      it 'should return error if requester doesnt have right to unregister', (done) ->

        client       = {}
        userFormData = generateDummyUserFormData()

        queue = [

          (next) ->
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              next()

          (next) ->
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist

              # set credentials
              { account, newToken }      = data
              client.sessionToken        = newToken
              client.connection.delegate = account
              next()

          (next) ->
            # username won't matter, only client's account will be checked
            JUser.unregister client, generateRandomUsername(), (err) ->
              expect(err?.message).to.be.equal 'You must confirm this action!'
              next()

        ]

        async.series queue, done


      it 'user should be updated if requester has the right to unregister', (done) ->

        client              = {}
        userFormData        = generateDummyUserFormData()
        { email, username } = userFormData

        queue = [

          (next) ->
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              next()

          (next) ->
            # registering user
            JUser.convert client, userFormData, (err, data) ->
              expect(err).to.not.exist

              # set credentials
              { account, newToken }      = data
              client.sessionToken        = newToken
              client.connection.delegate = account
              next()

          (next) ->
            # expecting user to exist before unregister
            JUser.one { username }, (err, user) ->
              expect(err)           .to.not.exist
              expect(user)          .to.exist
              expect(user.email)    .to.be.equal email
              expect(user.username) .to.be.equal username
              next()

          (next) ->
            # expecting name to exist before unregister
            JName.one { name : username }, (err, name) ->
              expect(err)  .to.not.exist
              expect(name) .to.exist
              next()

          (next) ->
            # expecting user account to exist before unregister
            JAccount.one { 'profile.nickname' : username }, (err, account) ->
              expect(err)                  .to.not.exist
              expect(account)              .to.exist
              expect(account.type)         .to.be.equal 'registered'
              next()

          (next) ->
            # expecting successful unregister
            JUser.unregister client, username, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            # expecting user to be deleted after unregister
            JUser.one { username }, (err, user) ->
              expect(err)   .to.not.exist
              expect(user)  .to.not.exist
              next()

          (next) ->
            # expecting name to be deleted
            JName.one { name : username }, (err, name) ->
              expect(err)  .to.not.exist
              expect(name) .to.not.exist
              next()

          (next) ->
            # expecting user account to be deleted after unregister
            JAccount.one { 'profile.nickname' : username }, (err, account) ->
              expect(err)     .to.not.exist
              expect(account) .to.not.exist
              next()

        ]

        async.series queue, done


  describe '#verifyRecaptcha()', ->

    it 'should pass error if captcha code is empty', (done) ->

      params = { slug: 'koding' }
      captchaCode = ''

      JUser.verifyRecaptcha captchaCode, params, (err) ->
        expect(err?.message).to.be.equal 'Captcha not valid. Please try again.'
        done()


    it 'should pass error if captcha code is invalid', (done) ->

      params = { slug: 'koding' }
      captchaCode = 'someInvalidCaptchaCode'

      JUser.verifyRecaptcha captchaCode, params, (err) ->
        expect(err?.message).to.be.equal 'Captcha not valid. Please try again.'
        done()


  describe '#authenticateClient()', ->

    describe 'when there is no session for the given clientId', ->

      it 'should create a new session', (done) ->

        JUser.authenticateClient 'someInvalidClientId', (err, data) ->
          expect(err).to.not.exist
          expect(data.session).to.be.an 'object'
          expect(data.session).to.have.property 'clientId'
          expect(data.session).to.have.property 'username'
          expect(data.account).to.be.an 'object'
          expect(data.account).to.have.property 'socialApiId'
          expect(data.account).to.have.property 'profile'
          done()


    describe 'when there is a session for the given clientId', ->

      it 'should return error if username doesnt exist in session', (done) ->

        sessionToken = null

        queue = [

          (next) ->
            generateDummyClient { gorup : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              { sessionToken } = client_
              next()

          (next) ->
            selector = { clientId : sessionToken }
            modifier = { $unset : { username : 1 } }
            JSession.update selector, modifier, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            JUser.authenticateClient sessionToken, (err, data) ->
              expect(err?.message).to.be.equal 'no username found'
              next()

        ]

        async.series queue, done


      it 'should be handle guest user if username starts with guest-', (done) ->

        guestUsername = "guest-#{generateRandomString 10}"
        sessionToken  = null

        queue = [

          (next) ->
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              { sessionToken } = client_
              next()

          (next) ->
            selector = { clientId : sessionToken }
            modifier = { $set : { username : guestUsername } }
            JSession.update selector, modifier, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            JUser.authenticateClient sessionToken, (err, data) ->
              expect(err).to.not.exist
              expect(data.session).to.be.an 'object'
              expect(data.account).to.be.an 'object'
              expect(data.account.profile.nickname).to.be.equal guestUsername
              expect(data.account.type).to.be.equal 'unregistered'
              next()

        ]

        async.series queue, done


      it 'should return error if username doesnt match any user', (done) ->

        sessionToken    = null
        invalidUsername = 'someInvalidUsername'

        queue = [

          (next) ->
            generateDummyClient { group: 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              { sessionToken } = client_
              next()

          (next) ->
            selector = { clientId: sessionToken }
            modifier = { $set: { username: invalidUsername }, $unset: { guestSessionBegan: 1 } }
            JSession.update selector, modifier, (err) ->
              expect(err).to.not.exist
              next()

          (next) ->
            JUser.authenticateClient sessionToken, (err, data) ->
              expect(err?.message).to.be.equal "no user found with
                                  #{invalidUsername} and sessionId"
              next()

        ]

        async.series queue, done


      it 'should return session and account if session is valid', (done) ->

        sessionToken = null

        queue = [

          (next) ->
            generateDummyClient { gorup : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              { sessionToken } = client_
              next()

          (next) ->
            JUser.authenticateClient sessionToken, (err, data) ->
              expect(err).to.not.exist
              expect(data.session).to.be.an 'object'
              expect(data.session).to.have.property 'clientId'
              expect(data.session).to.have.property 'username'
              expect(data.account).to.be.an 'object'
              expect(data.account).to.have.property 'socialApiId'
              expect(data.account).to.have.property 'profile'
              next()

        ]

        async.series queue, done

beforeTests()

runTests()

afterTests()
