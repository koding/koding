_        = require 'underscore'
hat      = require 'hat'
JAccount = require './lib/social/models/account'
JSession = require './lib/social/models/session'


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

    if account instanceof JAccount
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

    else
      callback 'session error'


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


module.exports = {
  generateUserInfo
  generateDummyClient
  generateCredentials
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  generateDummyUserFormData
}

