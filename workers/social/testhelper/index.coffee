_                       = require 'underscore'
hat                     = require 'hat'
JUser                   = require '../lib/social/models/user'
JGroup                  = require '../lib/social/models/group'
JAccount                = require '../lib/social/models/account'
JSession                = require '../lib/social/models/session'
Bongo                   = require 'bongo'

{ Relationship }        = require 'jraphical'
{ expect }              = require 'chai'
{ daisy, ObjectId }     = Bongo
{ argv }                = require 'optimist'
{ env : { MONGO_URL } } = process
KONFIG                  = require('koding-config-manager').load("main.#{argv.c}")
mongo                   = MONGO_URL or "mongodb://#{ KONFIG.mongo }"


checkBongoConnectivity = (callback) ->

  bongo = new Bongo
    root   : __dirname
    mongo  : mongo
    models :  '../lib/social/models'

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
  context            ?= { group : 'koding' }

  generateDummyClient context, (err, client) ->
    expect(err).to.not.exist
    account = client.connection?.delegate
    callback { client, account }


withConvertedUser = (opts, callback) ->

  [opts, callback] = [callback, opts]  unless callback
  opts ?= {}
  { context, userFormData, createGroup } = opts

  # if createGroup parameter is truthy generate random group slug
  groupSlug = if createGroup
  then generateRandomString()
  else 'koding'

  context      ?= { group : groupSlug }
  userFormData ?= generateDummyUserFormData()

  withDummyClient context, ({ client }) ->
    JUser.convert client, userFormData, (err, data) ->
      expect(err).to.not.exist
      { account, newToken, user } = data
      client.sessionToken         = newToken
      client.connection.delegate  = account

      fetchOrCreateGroup client, opts, (group) ->
        if opts?.userFormData?
        then callback { client, user, account, group, sessionToken : newToken }
        else callback { client, user, account, group, sessionToken : newToken, userFormData }


withCreatedUser = (opts, callback) ->

  [opts, callback] = [callback, opts]  unless callback

  user     = {}
  account  = {}
  userInfo = _.extend generateUserInfo(), opts

  withDummyClient opts, ({ client }) ->

    JUser.createUser userInfo, (err, user_, account_) ->
      expect(err).to.not.exist
      [user, account] = [user_, account_]

      fetchOrCreateGroup client, opts, (group) ->
        callback { client, user, account, group }


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


expectAccessDenied = (caller, callee, args..., callback) ->

  withDummyClient ({ client }) ->

    kallback = (err) ->
      expect(err?.message).to.be.equal 'Access denied'
      callback()

    if    args.length > 0
    then  caller[callee] client, args..., kallback
    else  caller[callee] client, kallback


fetchRelation = (options, callback) ->

  Relationship.one options, (err, relationship) ->
    expect(err).to.not.exist
    callback relationship


fetchOrCreateGroup = (client, opts, callback) ->

  [opts, callback] = [callback, opts]  unless callback
  opts ?= {}

  slug = client?.context?.group
  JGroup.one { slug }, (err, group) ->
    expect(err).to.not.exist
    return callback group  if group or not opts.createGroup

    # no group found, let's create one
    groupData = _.extend
      slug           : slug
      title          : slug
      visibility     : 'visible'
      allowedDomains : [ 'koding.com' ]
    , opts.groupData

    account = client?.connection?.delegate
    JGroup.create client, groupData, account, (err, group) ->
      expect(err).to.not.exist
      callback group


expectRelation = {

  toExist : (options, callback) ->
    fetchRelation options, (relationship) ->
      expect(relationship).to.exist
      callback relationship

  toNotExist : (options, callback) ->
    fetchRelation options, (relationship) ->
      expect(relationship).to.not.exist
      callback relationship

}


module.exports = {
  _
  daisy
  expect
  KONFIG
  ObjectId
  expectRelation
  withDummyClient
  withCreatedUser
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

