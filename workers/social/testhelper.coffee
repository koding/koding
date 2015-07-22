_   = require 'underscore'
hat = require 'hat'


# returns 20 characters by default
generateRandomString = (length = 20) -> hat().slice(32 - length)


generateRandomEmail = (domain = 'koding.com') ->

  return "kodingtestuser+#{generateRandomString()}@#{domain}"


generateRandomUsername = -> generateRandomString()


generateDummyClientData = ->

  dummyClient =
    sessionToken              : ''
    context                   :
      group                   : 'koding'
    clientIP                  : '127.0.0.1'
    connection                :
      delegate                :
        bongo_                :
          instanceId          : ''
          constructorName     : 'JAccount'
        data                  :
          profile             :
            nickname          : 'guest-a974470194e85106'
          type                : 'unregistered'
        type                  : 'unregistered'
        profile               :
          nickname            : 'guest-a974470194e85106'
        meta                  :
          data                : {}

  return dummyClient


generateDummyUserFormData = ->

  dummyUserFormData =
    email                     : generateRandomEmail()
    agree                     : 'on'
    password                  : 'testpass'
    username                  : 'testacc'
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
  generateCredentials
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  generateDummyClientData
  generateDummyUserFormData
}

