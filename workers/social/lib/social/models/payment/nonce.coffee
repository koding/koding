{ Module } = require 'jraphical'

module.exports = class JPaymentFulfillmentNonce extends Module

  { ObjectId, signature } = require 'bongo'

  @set
    sharedEvents :
      static     : []
      instance   : []
    schema       :
      nonce      :
        type     : String
        default  : require 'hat'
      planCode   : String
      subscriptionCode: String
      action     :
        type     : String
        enum     : ['Invalid nonce action'
                   [
                     'debit'
                     'credit'
                     'used'
                   ]]
    relationships  :
      owner        :
        targetType : "JAccount"
        as         : "owner"
