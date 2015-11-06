Bongo                               = require 'bongo'
koding                              = require './../bongo'

{ Relationship }                    = require 'jraphical'
{ daisy
  expect
  request
  convertToArray
  generateRandomEmail
  generateRandomString }            = require '../../../testhelper'
{ testCsrfToken }                   = require '../../../testhelper/handler'
{ generateRegisterRequestParams }   = require '../../../testhelper/handler/registerhelper'
{ generateJoinTeamRequestParams
  generateCreateTeamRequestParams } = require '../../../testhelper/handler/teamhelper'

JUser                               = require '../../../models/user'
JGroup                              = require '../../../models/group'
JAccount                            = require '../../../models/account'
JSession                            = require '../../../models/session'
JInvitation                         = require '../../../models/invitation'


# here we have actual tests
runTests = -> describe 'server.handlers.jointeam', ->

  it 'should send HTTP 403 if _csrf token is invalid', (done) ->

    testCsrfToken generateJoinTeamRequestParams, 'post', done


  it 'should send HTTP 301 if redirect is set', (done) ->

    postParams = generateJoinTeamRequestParams
      body        :
        redirect  : 'www.someurl.com'

    request.post postParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 301
      done()


  # joining an unregistered user to the newly created team
  it 'should be able to join unregistered invitee with valid data', (done) ->

    slug                    = generateRandomString()
    token                   = ''
    groupId                 = ''
    accountId               = ''
    inviteeEmail            = generateRandomEmail()
    inviteeUsername         = generateRandomString()

    queue = [

      ->
        options = { body : { slug, companyName : slug, invitees : inviteeEmail } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          # expecting HTTP 200 status code
          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            queue.next()

      ->
        # expecting invitation to be created
        params = { email : inviteeEmail }

        JInvitation.one params, (err, invitation) ->
          expect(err)                   .to.not.exist
          expect(invitation)            .to.exist
          expect(invitation.code)       .to.exist
          expect(invitation.email)      .to.be.equal inviteeEmail
          expect(invitation.status)     .to.be.equal 'pending'
          expect(invitation.groupName)  .to.be.equal slug

          # saving user invitation token
          token = invitation.code
          queue.next()

      ->
        joinTeamRequestParams = generateJoinTeamRequestParams
          body       :
            slug     : slug
            token    : token
            username : inviteeUsername

        request.post joinTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting invitation status to be changed after invitee joins
        params = { email : inviteeEmail }

        JInvitation.one params, (err, invitation) ->
          expect(err)               .to.not.exist
          expect(invitation)        .to.exist
          expect(invitation.status) .to.be.equal 'accepted'

          # saving user invitation token
          token = invitation.code
          queue.next()

      ->
        # expecting session to be created
        params = { username : inviteeUsername }

        JSession.one params, (err, session) ->
          expect(err)               .to.not.exist
          expect(session)           .to.exist
          expect(session.username)  .to.be.equal inviteeUsername
          queue.next()

      ->
        # expecting account to be saved and holding accountId
        params = { 'profile.nickname' : inviteeUsername }

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
        # expecting account also to be saved as a group member
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

      -> done()

    ]

    daisy queue


  # joining already registered user to the newly created team
  it 'should be able to join already registered invitee with valid data', (done) ->

    slug                    = generateRandomString()
    token                   = ''
    username                = generateRandomString()
    password                = 'testpass'
    inviteeEmail            = generateRandomEmail()

    registerRequestParams   = generateRegisterRequestParams
      body            :
        email         : inviteeEmail
        username      : username
        password      : password

    queue = [

      ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        options = { body : { slug, invitees : inviteeEmail, companyName : slug } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          # expecting team to be created successfully
          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            queue.next()

      ->
        # expecting invitation to be created
        params = { email : inviteeEmail }

        JInvitation.one params, (err, invitation) ->
          expect(err)                   .to.not.exist
          expect(invitation)            .to.exist
          expect(invitation.code)       .to.exist
          expect(invitation.email)      .to.be.equal inviteeEmail
          expect(invitation.status)     .to.be.equal 'pending'
          expect(invitation.groupName)  .to.be.equal slug

          # saving user invitation token
          token = invitation.code
          queue.next()

      ->
        # expecting already registered to be able to join to the team
        joinTeamRequestParams = generateJoinTeamRequestParams
          body       :
            slug     : slug
            token    : token

        request.post joinTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting invitation status to be changed after invitee joins
        params = { email : inviteeEmail }

        JInvitation.one params, (err, invitation) ->
          expect(err)               .to.not.exist
          expect(invitation)        .to.exist
          expect(invitation.status) .to.be.equal 'accepted'

          # saving user invitation token
          token = invitation.code
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should handle unregistered user with an email from an allowed domain', (done) ->

    slug                    = generateRandomString()
    domains                 = 'gmail.com, koding.com'
    domainsArray            = convertToArray domains

    testAllowedDomain = (queue, domain, slug) ->
      queue.push ->
        # generating random email with the allowed domain
        joinTeamRequestParams = generateJoinTeamRequestParams
          body       :
            slug     : slug
            email    : "#{generateRandomString()}@#{domain}"

        request.post joinTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

    queue = [

      ->
        options = { body : { slug, domains } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          # expecting HTTP 200 status code
          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            queue.next()

    ]

    for domain in domainsArray
      testAllowedDomain queue, domain, slug

    queue.push -> done()

    daisy queue


  it 'should handle already registered user with an email from an allowed domain', (done) ->

    slug                    = generateRandomString()
    username                = generateRandomString()
    password                = 'testpass'
    allowedDomain           = 'gmail.com'
    inviteeEmail            = "#{generateRandomString()}@#{allowedDomain}"

    registerRequestParams   = generateRegisterRequestParams
      body            :
        email         : inviteeEmail
        username      : username
        password      : password

    queue = [

      ->
        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        options = { body : { slug, domains : allowedDomain } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          # expecting HTTP 200 status code
          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            queue.next()

      ->
        # expecting HTTP 400 with invalid username
        joinTeamRequestParams = generateJoinTeamRequestParams
          body            :
            slug          : slug
            email         : "#{generateRandomString()}@#{allowedDomain}"
            username      : 'invalidUsername'
            alreadyMember : 'true'

        request.post joinTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 400
          expect(body)            .to.be.equal 'Unknown user name'
          queue.next()

      ->
        # expecting HTTP 400 with invalid password
        joinTeamRequestParams = generateJoinTeamRequestParams
          body            :
            slug          : slug
            email         : "#{generateRandomString()}@#{allowedDomain}"
            username      : username
            password      : 'someInvalidPassword'
            alreadyMember : 'true'

        request.post joinTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 400
          expect(body)            .to.be.equal 'Access denied!'
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 400 if user email is not in allowedDomains', (done) ->

    slug                    = generateRandomString()
    domains                 = 'gmail.com, koding.com'
    domainsArray            = convertToArray domains

    queue = [

      ->
        options = { body : { slug, domains } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          # expecting HTTP 200 status code
          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            queue.next()

      ->
        joinTeamRequestParams = generateJoinTeamRequestParams
          body       :
            slug     : slug
            email    : 'notinallowed@domains.com'

        expectedBody = 'Your email domain is not in allowed domains for this group'
        request.post joinTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 400
          expect(body)            .to.be.equal expectedBody
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 400 if invitee token is invalid', (done) ->

    slug                    = generateRandomString()
    inviteeEmail            = generateRandomEmail()

    joinTeamRequestParams = generateJoinTeamRequestParams
      body       :
        slug     : slug
        token    : 'someInvalidToken'

    queue = [

      ->
        options = { body : { slug, companyName : slug, invitees : inviteeEmail } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          # expecting HTTP 200 status code
          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            queue.next()

      ->
        # expecting HTTP 400 using invalid token
        request.post joinTeamRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 400
          expect(body)            .to.be.equal 'Invalid invitation code!'
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 400 if alreadyMember sent with wrong value', (done) ->

    joinTeamRequestParams = generateJoinTeamRequestParams
      body            :
        alreadyMember : 'true'

    # expecting HTTP 400 sending wrong alreadyMember value
    request.post joinTeamRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      expect(body)            .to.be.equal 'Unknown user name'
      done()


  it 'should send HTTP 400 if username is not set', (done) ->

    joinTeamRequestParams = generateJoinTeamRequestParams
      body         :
        username   : ''

    expectedBody = 'Errors were encountered during validation: username'
    request.post joinTeamRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      expect(body)            .to.be.equal expectedBody
      done()


  it 'should send HTTP 400 if passwords do not match', (done) ->

    joinTeamRequestParams = generateJoinTeamRequestParams
      body              :
        password        : 'somePassword'
        passwordConfirm : 'anotherPassword'

    request.post joinTeamRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 400
      expect(body)            .to.be.equal 'Passwords must match!'
      done()


runTests()

