{ argv }                      = require 'optimist'
{ expect }                    = require 'chai'
{ env : { MONGO_URL } }       = process
KONFIG                        = require('koding-config-manager').load("main.#{argv.c}")
mongo                         = MONGO_URL or "mongodb://#{ KONFIG.mongo }"
Bongo                         = require 'bongo'
{ daisy }                     = Bongo
JUser                         = require './user'
JGroup                        = require './group'
JAccount                      = require './account'
JSession                      = require './session'
JInvitation                   = require './invitation'
{ generateRandomEmail
  generateDummyClient
  generateRandomString
  generateDummyUserFormData } = require '../../../testhelper'


registerUserGenerateGroup = (adminClient, adminUserFormData, callback) ->

  # create our admin user
  JUser.convert adminClient, adminUserFormData, (err, data) ->
    expect(err).to.not.exist
    { account, newToken }   = data

    # set credentials
    adminClient.sessionToken        = newToken
    adminClient.connection.delegate = account

    # generate group creation data
    groupData =
      slug           : generateRandomString()
      visibility     : 'visible'
      title          : generateRandomString()
      allowedDomains : [ 'koding.com' ]

    # create the group
    JGroup.create adminClient, groupData, account, (err, data) ->
      group = data
      adminClient.context.group = group.slug # set our new group's name
      callback err, group


# making sure we have mongo connection before tests
beforeTests = -> before (done) ->

  bongo = new Bongo
    root   : __dirname
    mongo  : mongo
    models : ''

  bongo.once 'dbClientReady', ->
    done()


# here we have actual tests
runTests = ->

  describe 'workers.social.invitation.create', ->

    describe 'if user is not a member yet', ->

      it 'should receive the invitation', (done) ->

        group             = {}
        client            = {}
        adminClient       = {}
        userFormData      = generateDummyUserFormData()
        adminUserFormData = generateDummyUserFormData()

        queue = [

          ->
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              adminClient = client_
              queue.next()

          ->
            # registering admin and generating a new group
            registerUserGenerateGroup adminClient, adminUserFormData, (err, group_) ->
              expect(err).to.not.exist
              group = group_
              queue.next()

          ->
            # generating new client object and setting it's group context
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              client.context.group = group.slug
              queue.next()

          ->
            # creating an invitation for the unregistered user
            invitationReq = {
              invitations:[
                { email: userFormData.email }
              ]
            }

            JInvitation.create adminClient, invitationReq, (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            # expecting invitation to exist
            params = { email: userFormData.email, groupName: client.context.group }
            JInvitation.one params, (err, invitation) ->
              expect(err).to.not.exist
              expect(invitation).to.exist
              queue.next()

          -> done()

        ]

        daisy queue


    describe 'if user is already member', ->

      it 'should not receive the invitation', (done) ->

        group             = {}
        client            = {}
        adminClient       = {}
        userFormData      = generateDummyUserFormData()
        adminUserFormData = generateDummyUserFormData()

        queue = [

          ->
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              client = client_
              client.context.group = group.slug
              queue.next()

          ->
            generateDummyClient { group : 'koding' }, (err, client_) ->
              expect(err).to.not.exist
              adminClient = client_
              queue.next()

          ->
            # registering admin and generating a new group
            registerUserGenerateGroup adminClient, adminUserFormData, (err, group_) ->
              expect(err).to.not.exist
              group = group_
              # setting client's group slug as newly generated group's slug
              client.context.group = group.slug
              queue.next()

          ->
            # registering user
            JUser.convert client, userFormData, (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            # trying to create an invitation for user's email
            invitationReq = {
              invitations:[
                { email: userFormData.email }
              ]
            }

            JInvitation.create adminClient, invitationReq, (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            # expecting invitation not to be created
            params = { email: userFormData.email, groupName: group.slug }
            JInvitation.one params, (err, invitation) ->
              expect(err).to.not.exist
              expect(invitation).to.not.exist
              queue.next()

          -> done()

        ]

        daisy queue


beforeTests()

runTests()
