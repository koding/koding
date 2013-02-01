{Module} = require 'jraphical'
{Model} = require 'bongo'

class MembershipVerificationType extends Model
  @setSchema
    strategy  :
      type    : String
      enum    : ['invalid verification type', [
        'webhook', 'decoupled webhook', 'manual approval tokens'
        'personal invitations', 'multiuser invitations'
      ]]

module.exports = class MembershipPolicy extends Module

  @set
    schema    :
      verificationType  : [MembershipVerificationType]
      explanation       : String
