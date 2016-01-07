Bongo                                   = require 'bongo'
koding                                  = require './../bongo'

{ daisy }                               = Bongo
{ expect }                              = require 'chai'
{ Relationship }                        = require 'jraphical'
{ generateUrl
  generateRandomEmail
  generateRandomString }                = require '../../../testhelper'
{ generateRegisterRequestParams }       = require '../../../testhelper/handler/registerhelper'

{ generateCreateTeamRequestParams
  generateGetTeamMembersRequestParams } = require '../../../testhelper/handler/teamhelper'

request                                 = require 'request'
querystring                             = require 'querystring'

JGroup                                  = null
JInvitation                             = null


# here we have actual tests
runTests = -> describe 'server.handlers.getteammembers', ->

  beforeEach (done) ->

    # including models before each test case, requiring them outside of
    # tests suite is causing undefined errors
    { JGroup
      JInvitation } = koding.models

    done()


  it 'should send HTTP 404 if group does not exist', (done) ->

    getTeamMembersRequestParams = generateGetTeamMembersRequestParams
      groupSlug : 'someInvalidGroup'

    request.post getTeamMembersRequestParams, (err, res, body) ->
      expect(err)             .to.not.exist
      expect(res.statusCode)  .to.be.equal 404
      expect(body)            .to.be.equal 'no group found'
      done()


  it 'should send HTTP 403 when token is not set', (done) ->

    groupSlug = generateRandomString()

    queue = [

      ->
        options = { body : { slug : groupSlug } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            queue.next()

      ->
        getTeamMembersRequestParams = generateGetTeamMembersRequestParams
          groupSlug : groupSlug
          body      :
            token   : ''

        request.get getTeamMembersRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 403
          expect(body)            .to.be.equal 'not authorized'
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 403 when token is invalid', (done) ->

    groupSlug = generateRandomString()

    queue = [

      ->
        options = { body : { slug : groupSlug } }
        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            queue.next()

      ->
        getTeamMembersRequestParams = generateGetTeamMembersRequestParams
          groupSlug : groupSlug
          body      :
            token   : 'someInvalidToken'

        request.post getTeamMembersRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 403
          expect(body)            .to.be.equal 'not authorized'
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 200 when valid data provided with unregistered user', (done) ->

    token              = ''
    groupSlug          = generateRandomString()
    inviteeEmail       = generateRandomEmail()
    groupOwnerUsername = generateRandomString()
    groupOwnerPassword = generateRandomEmail()

    queue = [

      ->
        # expecting team to be created
        options =
          body              :
            slug            : groupSlug
            invitees        : inviteeEmail
            username        : groupOwnerUsername
            password        : groupOwnerPassword
            passwordConfirm : groupOwnerPassword

        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            queue.next()

      ->
        # expecting group to be crated
        JGroup.one { slug :groupSlug }, (err, group) ->
          expect(err)         .to.not.exist
          expect(group)       .to.exist
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
          expect(invitation.groupName)  .to.be.equal groupSlug

          token = invitation.code
          queue.next()

      ->
        # expecting to be able to get team members data
        url = generateUrl
          route : "-/team/#{groupSlug}/members?token=#{token}&limit=10"

        getTeamMembersRequestParams = generateGetTeamMembersRequestParams
          url     : url
          body    :
            token : token

        request.get getTeamMembersRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          expect(body)            .not.to.be.empty
          expect(body)            .to.contain groupOwnerUsername
          queue.next()

      -> done()

    ]

    daisy queue


  it 'should send HTTP 200 when valid data provided with registered user', (done) ->

    token              = ''
    groupSlug          = generateRandomString()
    inviteeEmail       = generateRandomEmail()
    inviteeUsername    = generateRandomString()
    groupOwnerEmail    = generateRandomEmail()
    groupOwnerUsername = generateRandomString()
    groupOwnerPassword = 'testpass'

    queue = [

      ->
        # expecting user to be registered
        registerRequestParams = generateRegisterRequestParams
          body              :
            email           : inviteeEmail
            username        : inviteeUsername
            password        : inviteeUsername
            passwordConfirm : inviteeUsername

        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting user to be registered
        registerRequestParams = generateRegisterRequestParams
          body              :
            email           : groupOwnerEmail
            username        : groupOwnerUsername
            password        : groupOwnerPassword
            passwordConfirm : groupOwnerPassword

        # registering a new user
        request.post registerRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          queue.next()

      ->
        # expecting team to be created
        options =
          body              :
            slug            : groupSlug
            email           : groupOwnerEmail
            invitees        : inviteeEmail
            username        : groupOwnerUsername
            password        : groupOwnerPassword
            alreadyMember   : 'true'
            passwordConfirm : groupOwnerPassword


        generateCreateTeamRequestParams options, (createTeamRequestParams) ->

          request.post createTeamRequestParams, (err, res, body) ->
            expect(err)             .to.not.exist
            expect(res.statusCode)  .to.be.equal 200
            queue.next()

      ->
        # expecting group to be crated
        JGroup.one { slug : groupSlug }, (err, group) ->
          expect(err)         .to.not.exist
          expect(group)       .to.exist
          queue.next()

      ->
        # expecting invitation to be created with correct data
        params = { email : inviteeEmail, groupName : groupSlug }

        JInvitation.one params, (err, invitation) ->
          expect(err)                   .to.not.exist
          expect(invitation)            .to.exist
          expect(invitation.code)       .to.exist
          expect(invitation.email)      .to.be.equal inviteeEmail
          expect(invitation.status)     .to.be.equal 'pending'
          expect(invitation.groupName)  .to.be.equal groupSlug

          token = invitation.code
          queue.next()

      ->
        # expecting to be able to get team members data
        url = generateUrl
          route : "-/team/#{groupSlug}/members?token=#{token}&limit=10"

        getTeamMembersRequestParams = generateGetTeamMembersRequestParams
          url     : url
          body    :
            token : token

        # expecting groupOwner's username to exist in the body
        request.get getTeamMembersRequestParams, (err, res, body) ->
          expect(err)             .to.not.exist
          expect(res.statusCode)  .to.be.equal 200
          expect(body)            .not.to.be.empty
          expect(body)            .to.contain groupOwnerUsername
          queue.next()

      -> done()

    ]

    daisy queue



runTests()
