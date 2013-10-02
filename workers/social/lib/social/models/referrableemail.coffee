jraphical = require "jraphical"
module.exports = class JReferrableEmail extends jraphical.Module
  JAccount           = require "./account"
  {ObjectId, secure} = require "bongo"

  @share()

  @set
    schema        :
      email       :
        type      : String
        email     : yes
      invited     :
        type      : Boolean
        default   : false
      originType  : String
      originId    : ObjectId
      createdAt   :
        type      : Date
        default   : -> new Date
      modifiedAt  :
        type      : Date
        get       : -> new Date
    sharedMethods :
      static      : ["create", "getUninvitedEmails"]

  @create: secure (client, email, callback)->
    JAccount.one {"profile.nickname": client.context.user}, (err, account)=>
      return err  if err
      r = new JReferrableEmail {
        email
        originId   : client.connection.delegate.getId()
        originType : "JAccount"
      }
      r.save (err)-> callback

  @getUninvitedEmails: secure (client, callback)->
    query =
      originId : client.connection.delegate.getId()
      invited  : false
    JReferrableEmail.some query, {}, callback
