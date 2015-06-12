_   = require 'underscore'
hat = require 'hat'


# returns 20 characters by default
generateRandomString = (length = 20) ->

  return hat().slice(32 - length)


generateDummyClientData = ->

  dummyClient =
    sessionToken              : ""
    context                   :
      group                   : "koding"
    clientIP                  : "127.0.0.1"
    connection                :
      delegate                :
        bongo_                :
          instanceId          : ""
          constructorName     : "JAccount"
        data                  :
          profile             :
            nickname          : "guest-a974470194e85106"
          type                : "unregistered"
        type                  : "unregistered"
        profile               :
          nickname            : "guest-a974470194e85106"
        meta                  :
          data                : {}

  return dummyClient


generateDummyUserFormData = ->

  dummyUserFormData =
    email                     : "testacc@gmail.com",
    agree                     : "on"
    password                  : "testpass",
    username                  : "testacc",
    passwordConfirm           : "testpass"

  return dummyUserFormData


generateCredentials = (opts = {}) ->

  credentials =
    username       : 'devrim',
    password       : 'devrim',
    tfcode         : '',
    groupName      : 'koding',
    invitationToken: undefined

  credentials = _.extend credentials, opts

  return credentials


generateUserInfo = (opts = {}) ->

  userInfo =
    email           : "kodingtestuser+#{generateRandomString()}@gmail.com"
    username        : generateRandomString()
    password        : "testtest"
    lastName        : "user"
    firstName       : "kodingtest"
    foreignAuth     : null
    emailFrequency  : null
    passwordStatus  : "valid"

  userInfo = _.extend userInfo, opts

  return userInfo


module.exports = {
  generateUserInfo
  generateCredentials
  generateRandomString
  generateDummyClientData
  generateDummyUserFormData
}
