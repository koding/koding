{AttributeSetter} = require('./attribute_setter')

class CreditCard extends AttributeSetter
  constructor: (attributes) ->
    super attributes
    @maskedNumber = "#{@bin}******#{@last4}"
    @expirationDate = "#{@expirationMonth}/#{@expirationYear}"

exports.CreditCard = CreditCard
