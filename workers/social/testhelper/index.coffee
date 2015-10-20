_                       = require 'underscore'
hat                     = require 'hat'
JUser                   = require '../lib/social/models/user'
JAccount                = require '../lib/social/models/account'
JSession                = require '../lib/social/models/session'
Bongo                   = require 'bongo'

{ expect }              = require 'chai'
{ daisy }               = Bongo
{ argv }                = require 'optimist'
{ env : { MONGO_URL } } = process
KONFIG                  = require('koding-config-manager').load("main.#{argv.c}")
mongo                   = MONGO_URL or "mongodb://#{ KONFIG.mongo }"


checkBongoConnectivity = (callback) ->

  bongo = new Bongo
    root   : __dirname
    mongo  : mongo
    models : ''

  bongo.once 'dbClientReady', ->
    callback()


# returns 20 characters by default
generateRandomString = (length = 20) -> hat().slice(32 - length)


generateRandomEmail = (domain = 'koding.com') ->

  return "kodingtestuser+#{generateRandomString()}@#{domain}"


generateRandomUsername = -> generateRandomString()


generateDummyClient = (context, callback) ->

  # creating session and account
  JSession.createSession (err, data) ->
    callback err  if err

    { session, account } = data
    context ?= { group: session?.groupName ? 'koding' }

    return callback 'session error'  unless account instanceof JAccount

    { clientIP, clientId } = session

    # replace token with session.clientid
    sessionToken = clientId

    # setting client data
    client =
      sessionToken : sessionToken
      context      : context
      clientIP     : '127.0.0.1'
      connection   :
        delegate   : account

    callback null, client


withDummyClient = (context, callback) ->

  [context, callback] = [callback, context]  unless callback
  context         ?= { group : 'koding' }

  generateDummyClient context, (err, client) ->
    expect(err).to.not.exist
    callback { client }


withConvertedUser = (opts, callback) ->

  [opts, callback]          = [callback, opts]  unless callback
  { context, userFormData } = opts  if opts

  context      ?= { group : 'koding' }
  userFormData ?= generateDummyUserFormData()

  withDummyClient context, ({ client }) ->
    JUser.convert client, userFormData, (err, data) ->
      expect(err).to.not.exist
      { account, newToken }      = data
      client.sessionToken        = newToken
      client.connection.delegate = account

      if opts?.userFormData?
      then callback { client, account, sessionToken : newToken }
      else callback { client, account, sessionToken : newToken, userFormData }


generateDummyUserFormData = (opts = {}) ->

  dummyUserFormData =
    email                     : generateRandomEmail()
    agree                     : 'on'
    password                  : 'testpass'
    username                  : generateRandomUsername()
    passwordConfirm           : 'testpass'

  dummyUserFormData = _.extend dummyUserFormData, opts

  return dummyUserFormData


generateCredentials = (opts = {}) ->

  credentials =
    tfcode              : ''
    username            : 'devrim'
    password            : 'devrim'
    groupName           : 'koding'
    invitationToken     : undefined
    groupIsBeingCreated : no

  credentials = _.extend credentials, opts

  return credentials


generateUserInfo = (opts = {}) ->

  userInfo =
    email           : "kodingtestuser+#{generateRandomString()}@gmail.com"
    username        : generateRandomUsername()
    password        : 'testpass'
    lastName        : 'user'
    firstName       : 'kodingtest'
    foreignAuth     : null
    emailFrequency  : null
    passwordStatus  : 'valid'

  userInfo = _.extend userInfo, opts

  return userInfo


generateRandomUserArray =  (count, callback) ->

  queue     = []
  userArray = []

  for i in [0...count]
    queue.push ->
      JUser.createUser generateUserInfo(), (err, user_) ->
        expect(err).to.not.exist
        userArray.push user_
        queue.next()

  queue.push -> callback userArray

  daisy queue


expectAccessDenied = (done, caller, callee, args...) ->

  withDummyClient ({ client }) ->
    caller[callee] client, args..., (err) ->
      expect(err?.message).to.be.equal 'Access denied'
      done()


module.exports = {
  _
  daisy
  expect
  withDummyClient
  generateUserInfo
  withConvertedUser
  expectAccessDenied
  generateDummyClient
  generateCredentials
  generateRandomEmail
  generateRandomString
  checkBongoConnectivity
  generateRandomUsername
  generateRandomUserArray
  generateDummyUserFormData
}

