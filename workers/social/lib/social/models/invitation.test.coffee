{ argv }                    = require 'optimist'
{ expect }                  = require "chai"
{ env : { MONGO_URL } }     = process
KONFIG                      = require('koding-config-manager').load("main.#{argv.c}")
mongo                       = MONGO_URL or "mongodb://#{ KONFIG.mongo }"
Bongo                       = require 'bongo'
{ daisy }                   = Bongo
JUser                       = require './user'
JGroup                      = require './group'
JAccount                    = require './account'
JInvitation                 = require './invitation'
JSession                    = require './session'
{ generateRandomString
  generateDummyClientData
  generateDummyUserFormData } = require '../../../testhelper'


bongo             = null
adminClient       = null
group             = null

runTests = ->

  before (done) ->
    adminClient = generateDummyClientData()
    adminUserFormData = generateDummyUserFormData()

    bongo = new Bongo
      root   : __dirname
      mongo  : mongo
      models : '../../models'

    bongo.once 'dbClientReady', ->

      # creating a session before running tests
      JSession.createSession (err, { session, account }) ->

        adminClient.sessionToken        = session.token
        adminClient.connection.delegate = account

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
            expect(err).to.not.exist

            group = data
            adminClient.context.group = group.slug # set our new group's name
            done()


  describe 'workers.social.invitation.create', ->
    client       = {}
    userFormData = {}

    beforeEach (done) ->
      # create session data before each test
      client = generateDummyClientData()
      client.context.group = group.slug
      userFormData = generateDummyUserFormData()

      JSession.createSession (err, { session, account }) ->
        expect(err).to.not.exist

        client.sessionToken        = session.token
        client.connection.delegate = account

        done()


    describe 'if user is not a member yet', ->

      it 'should receive the invitation', (done) ->
        queue = [

          ->
            invitationReq = {
              invitations:[
                { email: userFormData.email }
              ]
            }

            JInvitation.create adminClient, invitationReq, (err) ->
              expect(err).to.not.exist

          ->
              JInvitation.one { email: userFormData.email, groupName: client.context.group }, (err, invitation) ->
                expect(err).to.not.exist
                expect(invitation).to.exist

          -> done()

        ]

        daisy queue


    describe 'if user is already member', ->

      it 'should not receive the invitation', (done) ->

        queue = [

          ->
            JUser.convert client, userFormData, (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            invitationReq = {
              invitations:[
                { email: userFormData.email }
              ]
            }

            JInvitation.create adminClient, invitationReq, (err) ->
              expect(err).to.not.exist
              queue.next()

          ->
            JInvitation.one { email: userFormData.email, groupName: group.slug }, (err, invitation) ->
              expect(err).to.not.exist
              expect(invitation).to.not.exist
              queue.next()

          -> done()

        ]

        daisy queue

runTests()
