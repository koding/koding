{ Model, ObjectId } = require 'bongo'

# JDeletedMember stores deleted members for billing purposes
module.exports = class JDeletedMember extends Model

  @set
    sharedMethods : {}
    schema        :
      accountId   : ObjectId
      groupId     : ObjectId
