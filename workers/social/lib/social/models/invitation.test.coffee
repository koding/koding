{ argv }                      = require 'optimist'
{ expect }                    = require "chai"
{ env : {MONGO_URL} }         = process

KONFIG                        = require('koding-config-manager').load("main.#{argv.c}")

Bongo                         = require 'bongo'
JUser                         = require './user'
mongo                         = MONGO_URL or "mongodb://#{ KONFIG.mongo }"
JAccount                      = require './account'
JInvitation                   = require './invitation'
JSession                      = require './session'
Speakeasy                     = require 'speakeasy'
TestHelper                    = require '../../../testhelper'

{ daisy }                     = Bongo
{ generateUserInfo
  generateCredentials
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  generateDummyClientData
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


# here we have actual tests
runTests = ->
  describe 'workers.social.invitation.create', ->

    # variables that will be used in the convert test suite scope
    client       = {}
    userFormData = {}

    # this function will be called everytime before each test case under this test suite
    beforeEach ->

      # cloning the client and userFormData from dummy datas each time.
      # used pure nodejs instead of a library bcs we need deep cloning here.
      client                = JSON.parse JSON.stringify dummyClient
      userFormData          = JSON.parse JSON.stringify dummyUserFormData

      userFormData.email    = generateRandomEmail()
      userFormData.username = generateRandomUsername()

    describe 'if user is not a member yet', ->

      it 'should create/send the invitation', (done) ->

        JInvitation.create client, { invitations:[dummyUserFormData.email] }, (err)->
          expect(err).to.not.exist

          JInvitation.one {email: dummyUserFormData.email, groupName: client.context.group}, (err, invitation)->
            expect(err).to.not.exist
            expect(invitation).to.exist

    describe 'if user is a member yet', ->

      it 'should not create/send the invitation', (done) ->

        JUser.convert client, userFormData, (err) ->
          expect(err).to.not.exist

          JInvitation.create client, { invitations:[dummyUserFormData.email] }, (err)->
            expect(err).to.not.exist

            JInvitation.one {email: dummyUserFormData.email, groupName: client.context.group}, (err, invitation)->
              expect(err).to.not.exist
              expect(invitation).to.not.exist

          done()


beforeTests()

runTests()
