_        = require 'underscore'
hat      = require 'hat'
JUser    = require './lib/social/models/user/index'
JAccount = require './lib/social/models/account'


# returns 20 characters by default
generateRandomString = (length = 20) -> hat().slice(32 - length)


generateRandomEmail = (domain = 'koding.com') ->

  return "kodingtestuser+#{generateRandomString()}@#{domain}"


generateRandomUsername = -> generateRandomString()


generateDummyClient = (context, callback) ->

  # sending null session token to generate a new client
  JUser.authenticateClient null, (err, res = {}) ->

    return callback err  if err

    { account, session } = res
    context ?= { group: session?.groupName ? 'koding' }

    if account instanceof JAccount
      { clientIP, clientId } = session

      # replace token with session.clientid
      sessionToken = clientId

      client =
        sessionToken : sessionToken
        context      : context
        clientIP     : '127.0.0.1'
        connection   :
          delegate   : account

      callback null, client

    else
      callback 'session error'


generateDummyUserFormData = ->

  dummyUserFormData =
    email                     : generateRandomEmail()
    agree                     : 'on'
    password                  : 'testpass'
    username                  : generateRandomUsername()
    passwordConfirm           : 'testpass'

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


module.exports = {
  generateUserInfo
  generateDummyClient
  generateCredentials
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  generateDummyUserFormData
}

