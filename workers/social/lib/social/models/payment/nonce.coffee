{ Module } = require 'jraphical'

module.exports = class JPaymentFulfillmentNonce extends Module

  { ObjectId, signature } = require 'bongo'

  @set
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
                   ]]
