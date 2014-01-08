{ Model } = require 'bongo'

module.exports = class JPaymentFulfillmentNonce extends Model

  { ObjectId } = require 'bongo'

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
