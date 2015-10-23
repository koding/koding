koding                              = require './../bongo'
{ argv }                            = require 'optimist'
KONFIG                              = require('koding-config-manager').load "main.#{argv.c}"

{ hostname }                        = KONFIG
{ Relationship }                    = require 'jraphical'
{ daisy
  expect
  request
  convertToArray
  generateRandomEmail
  generateRandomString
  checkBongoConnectivity
  generateRandomUsername }          = require '../../../testhelper'
{ testCsrfToken }                   = require '../../../testhelper/handler'
{ generateRegisterRequestParams }   = require '../../../testhelper/handler/registerhelper'
{ generateCreateTeamRequestParams } = require '../../../testhelper/handler/teamhelper'

reservedTeamDomains = require '../../../../workers/social/lib/social/models/user/reservedteamdomains'

JUser                               = null
JName                               = null
JGroup                              = null
JAccount                            = null
JSession                            = null
JInvitation                         = null
JDomainAlias                        = null


beforeTests = -> before (done) ->

  checkBongoConnectivity done


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


  it 'should fail when csrf token is invalid', (done) ->

    options = { generateParamsAsync : true }
    testCsrfToken generateCreateTeamRequestParams, 'post', options, done


  # creating team with an unregistered user
  it 'should handle team creation correctly when valid data provided', (done) ->

    createTeamRequestParams = null

    companyName = "testcompany#{generateRandomString(10)}"

    slug               = companyName
    email              = generateRandomEmail()
    domains            = 'koding.com, gmail.com'
    username           = generateRandomUsername()
    inviteeEmail       = generateRandomEmail()
    invitees           = inviteeEmail
    companyName        = companyName

    queue = [

      ->
        options = { body : { slug, email, domains, username, invitees, companyName } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          # expecting HTTP 200 status code on team create request
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

    queue = [

      ->
        options = { body : { username, slug } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

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
    createTeamRequestParams = null

    registerRequestParams   = generateRegisterRequestParams
      body       :
        username : username
        password : password

    queue = [

      ->
        options = { body : { username, password, alreadyMember : 'true' } }
        generateCreateTeamRequestParams options, (createTeamRequestParams_) ->
          createTeamRequestParams = createTeamRequestParams_
          queue.next()

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

    options = { body : { invitees : '' } }
    generateCreateTeamRequestParams options, (createTeamRequestParams) ->

      request.post createTeamRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 200
        done()


  it 'should save emailFrequency.marketing according to newsletter param', (done) ->

    makeCreateTeamRequest = (username, newsletter) ->
      options = { body : { username, newsletter } }
      generateCreateTeamRequestParams options, (createTeamRequestParams) ->

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


  it 'should send HTTP 400 when company is not set', (done) ->

    options = { body : { companyName : '' } }
    generateCreateTeamRequestParams options, (createTeamRequestParams) ->

      request.post createTeamRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 400
        expect(body)            .to.be.equal 'Company name can not be empty.'
        done()


  it 'should send HTTP 400 when slug is not set', (done) ->

    options = { body : { slug : '' } }
    generateCreateTeamRequestParams options, (createTeamRequestParams) ->

      request.post createTeamRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 400
        expect(body)            .to.be.equal 'Group slug can not be empty.'
        done()


  it 'should send HTTP 400 when slug is invalid or a reserved one', (done) ->

    invalidTeamDomains = [
      # testing invalid domains
      '-'
      '-domain'
      'domain-'
      'domainCamelCase'
      'domain.with.dots'
      'domain with whitespaces'
      # testing some reserved domains
      reservedTeamDomains[0]
      reservedTeamDomains[Math.round(reservedTeamDomains.length / 2)]
      reservedTeamDomains[reservedTeamDomains.length - 1]
    ]

    queue = []

    invalidTeamDomains.forEach (teamDomain) ->

      queue.push ->
        options = { body : { slug : teamDomain } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 400
            expect(body)            .to.be.equal 'Invalid group slug.'
            queue.next()

    queue.push -> done()

    daisy queue


  it 'should send HTTP 403 when slug is set as koding', (done) ->

    options = { body : { slug : 'koding' } }
    generateCreateTeamRequestParams options, (createTeamRequestParams) ->

      expectedBody = "Sorry, Team URL 'koding.#{hostname}' is already in use"
      request.post createTeamRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 403
        expect(body)            .to.be.equal expectedBody
        done()


  it 'should send HTTP 403 when slug is set as an already used one', (done) ->

    slug                    = generateRandomString()

    queue = [

      ->
        options = { body : { slug } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          # expecting first team create request to be successful
          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            queue.next()

      ->
        options = { body : { slug } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          # expecting second team crete request with the same slug to fail
          expectedBody = "Sorry, Team URL '#{slug}.#{hostname}' is already in use"
          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(body)            .to.be.equal expectedBody
            expect(res.statusCode)  .to.be.equal 403
            expect(body)            .to.be.equal expectedBody
            queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 200 when user is registered but alreadyMember set to false', (done) ->

    email                   = generateRandomEmail()
    username                = generateRandomString()
    password                = 'testpass'

    registerRequestParams   = generateRegisterRequestParams
      body              :
        email           : email
        username        : username
        password        : password
        passwordConfirm : password

    queue = [

      ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        options = {
          body : {
            email, username, password
            passwordConfirm : password
            alreadyMember : 'false'
          }
        }

        generateCreateTeamRequestParams options, (createTeamRequestParams) ->
          # expecting user to create team when alreadyMember has wrong value
          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 400 when user is unregistered but alreadyMember set to true', (done) ->

    options = { body : { alreadyMember : 'true' } }
    generateCreateTeamRequestParams options, (createTeamRequestParams) ->

      # expecting user to create team when alreadyMember has wrong value
      request.post createTeamRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 400
        expect(body)            .to.be.equal 'Unknown user name'
        done()


  it 'should send HTTP 400 when email is not valid', (done) ->

    # setting email as random string
    options = { body : { email : generateRandomString(10) } }
    generateCreateTeamRequestParams options, (createTeamRequestParams) ->

      request.post createTeamRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 400
        done()


  it 'should send HTTP 400 when email is in use and username is not in use', (done) ->

    email                   = generateRandomEmail()
    username                = generateRandomString()
    anotherUsername         = generateRandomString()

    registerRequestParams   = generateRegisterRequestParams
      body        :
        email     : email
        username  : username

    queue = [

      ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        options = { body : { email, username : anotherUsername } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->
        #
          # expecting HTTP 400 from juser.convert
          expectedBody = 'Email is already in use!'
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

    options = { body : { username : '' } }
    generateCreateTeamRequestParams options, (createTeamRequestParams) ->

      request.post createTeamRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 400
        expect(body)            .to.be.equal expectedBody
        done()


  it 'should send HTTP 400 when passwords does not match', (done) ->

    # sending different passwords
    options =
      body              :
        password        : 'somePassword'
        passwordConfirm : 'anotherPassword'

    generateCreateTeamRequestParams options, (createTeamRequestParams) ->

      request.post createTeamRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 400
        expect(body)            .to.be.equal 'Passwords must match!'
        done()


  it 'should send HTTP 400 when agree is set as false', (done) ->

    expectedBody = 'Errors were encountered during validation: agree'

    options = { body : { agree : 'false' } }
    generateCreateTeamRequestParams options, (createTeamRequestParams) ->

      request.post createTeamRequestParams, (err, res, body) ->
        expect(err)             .to.not.exist
        expect(res.statusCode)  .to.be.equal 400
        expect(body)            .to.be.equal expectedBody
        done()


  describe 'when teamAccessCode is provided', ->

    it 'should send HTTP 400 if teamAccessCode non-existent', (done) ->

      expectedBody = 'Team Invitation is not found'

      options =
        body                 :
          teamAccessCode     : 'someNonExistentTeamAccessCode'
        createTeamInvitation : no

      generateCreateTeamRequestParams options, (createTeamRequestParams) ->

        request.post createTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 400
          expect(body)            .to.be.equal expectedBody
          done()


beforeTests()

runTests()

