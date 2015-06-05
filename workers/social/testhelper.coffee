hat = require 'hat'

module.exports =

  # returns 20 characters by default
  getRandomString : (length = 20) ->

    return hat().slice(32 - length)


  getDummyClientData : ->

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


  getDummyUserFormData : ->

    dummyUserFormData =
      email                     : "testacc@gmail.com",
      agree                     : "on"
      password                  : "testpass",
      username                  : "testacc",
      passwordConfirm           : "testpass"

    return dummyUserFormData


  getCredentials : ->

    credentials =
      username       : 'devrim',
      password       : 'devrim',
      tfcode         : '',
      groupName      : 'koding',
      invitationToken: undefined

    return credentials
