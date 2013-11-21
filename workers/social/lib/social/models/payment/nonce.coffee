{ Model } = require 'bongo'

module.exports = class JPaymentFulfillmentNonce extends Model

  { ObjectId } = require 'bongo'

  @set
    schema      :
      nonce     :
        type    : String
        default : require 'hat'
      productId : ObjectId
