{Module} = require 'jraphical'

module.exports = class JRecurlyPaymentMethod extends Module

  @share()

  @set
    schema      :
      recurlyId : String
