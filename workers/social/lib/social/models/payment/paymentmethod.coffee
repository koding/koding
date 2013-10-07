{Module} = require 'jraphical'

module.exports = class JPaymentPaymentMethod extends Module

  @share()

  @set
    schema      :
      recurlyId : String
