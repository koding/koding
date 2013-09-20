{ Model } = require 'bongo'

module.exports = class JRecurlyBillingMethod extends Model

  @set
    schema        :
      recurlyId   : String
      mixin       :
        company   : String