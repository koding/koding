Bongo                               = require "bongo"
koding                              = require './../bongo'

{ daisy }                           = Bongo
{ expect }                          = require "chai"
{ Relationship }                    = require 'jraphical'
{ TeamHandlerHelper
  generateRandomEmail
  generateRandomString
  RegisterHandlerHelper }           = require '../../../testhelper'

{ convertToArray
  generateCreateTeamRequestBody
  generateCreateTeamRequestParams } = TeamHandlerHelper

hat                                 = require 'hat'
request                             = require 'request'
querystring                         = require 'querystring'

JUser                               = null
JName                               = null
JGroup                              = null
JAccount                            = null
JSession                            = null
JInvitation                         = null
JDomainAlias                        = null


# here we have actual tests
runTests = -> describe 'server.handlers.createteam', ->

  beforeEach (done) ->

    # including models before each test case, requiring them outside of
    # tests suite is causing undefined errors
    { JUser
      JName
      JGroup
      JAccount
      JSession
      JInvitation
      JDomainAlias } = koding.models

    done()


  it 'should send HTTP 301 if request is not XHR', (done) ->

    postParams = generateCreateTeamRequestParams
      headers              :
        'x-requested-with' : 'this is not an XHR'

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 301
      done()


  # creating team with an unregistered user
  it 'should handle team creation correctly when valid data provided', (done) ->

    inviteeEmail            = generateRandomEmail()
    createTeamRequestParams = generateCreateTeamRequestParams
      body        :
        invitees  : inviteeEmail

    { slug
      email
      domains
      username
      companyName } = querystring.parse createTeamRequestParams.body

    queue = [

      ->
        # expecting HTTP 200 status code
        request.post createTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting user to be saved
        params = { username }

        JUser.one params, (err, user) ->
          expect(err)                  .to.not.exist
          expect(user.email)           .to.be.equal email
          expect(user.passwordStatus)  .to.be.equal 'valid'
          queue.next()

      ->
        # expecting group to be saved
        allowedDomains = convertToArray domains

        JGroup.one { slug }, (err, group) ->
          expect(err)         .to.not.exist
          expect(group.title) .to.be.equal companyName

          allowedDomains.forEach (domain) ->
            expect(group.allowedDomains).to.include domain
          queue.next()

      ->
        # expecting account to be saved
        params = { 'profile.nickname' : username }

        JAccount.one params, (err, account) ->
          expect(err)     .to.not.exist
          expect(account) .to.exist
          queue.next()

      ->
        # expecting domainAlias to be saved
        params = { domain : "#{username}.dev.koding.io" }

        JDomainAlias.one params, (err, domainAlias) ->
          expect(err)         .to.not.exist
          expect(domainAlias) .to.exist
          queue.next()

      ->
        # expecting name to be saved
        params = { name : username }

        JName.one params, (err, jname) ->
          expect(err)   .to.not.exist
          expect(jname) .to.exist
          queue.next()

      ->
        # expecting invitation to be created with correct data
        params = { email : inviteeEmail }

        JInvitation.one params, (err, invitation) ->
          expect(err)                   .to.not.exist
          expect(invitation)            .to.exist
          expect(invitation.code)       .to.exist
          expect(invitation.email)      .to.be.equal inviteeEmail
          expect(invitation.status)     .to.be.equal 'pending'
          expect(invitation.groupName)  .to.be.equal slug
          queue.next()

      ->
        # expecting session to be created
        params = { username }

        JSession.one params, (err, session) ->
          expect(err)               .to.not.exist
          expect(session)           .to.exist
          expect(session.username)  .to.be.equal username
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should save relationships correctly', (done) ->

    slug                    = generateRandomString()
    userId                  = ''
    groupId                 = ''
    username                = generateRandomString()
    accountId               = ''
    createTeamRequestParams = generateCreateTeamRequestParams
      body        :
        username  : username
        slug      : slug

    queue = [

      ->
        # expecting HTTP 200 status code
        request.post createTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting user to be saved and holding userId
        params = { username }

        JUser.one params, (err, user) ->
          expect(err)   .to.not.exist
          expect(user)  .to.exist
          userId = user._id
          queue.next()

      ->
        # expecting account to be saved and holding accountId
        params = { 'profile.nickname' : username }

        JAccount.one params, (err, account) ->
          expect(err)     .to.not.exist
          expect(account) .to.exist
          accountId = account._id
          queue.next()

      ->
        # expecting group to be saved and holding groupId
        params = { slug }

        JGroup.one params, (err, group) ->
          expect(err)     .to.not.exist
          expect(group)   .to.exist
          groupId = group._id
          queue.next()

      ->
        # expecting owner account of the group to be saved
        params =
          $and : [
            { as       : 'owner' }
            { sourceId : groupId }
            { targetId : accountId }
          ]

        Relationship.one params, (err, relationship) ->
          expect(err)          .to.not.exist
          expect(relationship) .to.exist
          queue.next()

      ->
        # expecting account also to be saved as a member
        params =
          $and : [
            { as       : 'member' }
            { sourceId : groupId }
            { targetId : accountId }
          ]

        Relationship.one params, (err, relationship) ->
          expect(err)          .to.not.exist
          expect(relationship) .to.exist
          queue.next()

      ->
        # expecting user to be saved as the owner of the account
        params =
          $and : [
            { as       : 'owner' }
            { sourceId : userId }
            { targetId : accountId }
          ]

        Relationship.one params, (err, relationship) ->
          expect(err)          .to.not.exist
          expect(relationship) .to.exist
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should handle correctly already registered user with valid data', (done) ->

    username                = generateRandomString()
    password                = 'testpass'

    createTeamRequestParams = generateCreateTeamRequestParams
      body            :
        username      : username
        password      : password
        alreadyMember : 'true'

    registerRequestParams   = RegisterHandlerHelper.generateRequestParams
      body       :
        username : username
        password : password

    queue = [

      ->
        # sending alreadyMember:true with unregistered username
        request.post createTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(body)            .to.be.equal 'Unknown user name'
          expect(res.statusCode)  .to.be.equal 400
          queue.next()

      ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting HTTP 200 with newly registered username
        request.post createTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 200 when invitees is not set', (done) ->

    createTeamRequestParams = generateCreateTeamRequestParams
      body       :
        invitees : ''

    request.post createTeamRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 200
      done()


  it 'should save emailFrequency.marketing according to newsletter param', (done) ->

    makeCreateTeamRequest = (username, newsletter) ->
      createTeamRequestParams = generateCreateTeamRequestParams
        body         :
          username   : username
          newsletter : newsletter

      request.post createTeamRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 200
        queue.next()

    username = ''

    queue = [

      ->
        username = generateRandomString()
        makeCreateTeamRequest(username, 'false')

      ->
        # expecting emailFrequency.marketing to be false
        params = { username }

        JUser.one params, (err, { data : { emailFrequency } }) ->
          expect(err)                       .to.not.exist
          expect(emailFrequency.marketing)  .to.be.false
          queue.next()

      ->
        username = generateRandomString()
        makeCreateTeamRequest(username, 'true')

      ->
        # expecting emailFrequency.marketing to be true
        params = { username }

        JUser.one params, (err, { data : { emailFrequency } }) ->
          expect(err)                       .to.not.exist
          expect(emailFrequency.marketing)  .to.be.true
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 500 when company is not set', (done) ->

    createTeamRequestParams = generateCreateTeamRequestParams
      body          :
        companyName : ''

    request.post createTeamRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 500
      expect(body)            .to.be.equal 'Couldn\'t create the group.'
      done()


  it 'should send HTTP 500 when slug is not set', (done) ->

    createTeamRequestParams = generateCreateTeamRequestParams
      body   :
        slug : ''

    request.post createTeamRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 500
      expect(body)            .to.be.equal 'Couldn\'t create the group.'
      done()


  it 'should send HTTP 500 when slug is set as koding', (done) ->

    createTeamRequestParams = generateCreateTeamRequestParams
      body   :
        slug : 'koding'

    request.post createTeamRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 500
      expect(body)            .to.be.equal 'Couldn\'t create the group.'
      done()


  it 'should send HTTP 400 when email is in use', (done) ->

    email                   = generateRandomEmail()
    registerRequestParams   = RegisterHandlerHelper.generateRequestParams
      body    :
        email : email

    createTeamRequestParams = generateCreateTeamRequestParams
      body    :
        email : email

    queue = [

      ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting HTTP 400 using already registered email
        request.post createTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 400
          expect(body)            .to.be.equal 'Email is already in use!'
          queue.next()

      -> done()

    ]

    daisy queue


  # TODO: this somehow returns 200, needs to be investigated
  it.skip 'should send HTTP 400 when email is not valid', (done) ->

    # setting email as random string
    createTeamRequestParams = generateCreateTeamRequestParams
      body    :
        email : generateRandomString 10

    request.post createTeamRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      done()


  it 'should send HTTP 400 when username is in use', (done) ->

    username                = generateRandomString()
    registerRequestParams   = RegisterHandlerHelper.generateRequestParams
      body        :
        username  : username

    createTeamRequestParams = generateCreateTeamRequestParams
      body        :
        username  : username

    queue = [

      ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting HTTP 400 using already registered username
        expectedBody = 'Errors were encountered during validation: username'
        request.post createTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 400
          expect(body)            .to.be.equal expectedBody
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 400 when username is not set', (done) ->

    expectedBody            = 'Errors were encountered during validation: username'
    createTeamRequestParams = generateCreateTeamRequestParams
      body        :
        username  : ''

    request.post createTeamRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      expect(body)            .to.be.equal expectedBody
      done()


  it 'should send HTTP 400 when passwords does not match', (done) ->

    # sending different passwords
    createTeamRequestParams = generateCreateTeamRequestParams
      body              :
        password        : 'somePassword'
        passwordConfirm : 'anotherPassword'

    request.post createTeamRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      expect(body)            .to.be.equal 'Passwords must match!'
      done()


  it 'should send HTTP 400 when agree is set as false', (done) ->

    expectedBody            = 'Errors were encountered during validation: agree'
    createTeamRequestParams = generateCreateTeamRequestParams
      body    :
        agree : 'false'

    request.post createTeamRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      expect(body)            .to.be.equal expectedBody
      done()


runTests()

