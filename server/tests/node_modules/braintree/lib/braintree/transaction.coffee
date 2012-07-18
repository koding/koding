{AttributeSetter} = require('./attribute_setter')
{CreditCard} = require('./credit_card')

class Transaction extends AttributeSetter
  constructor: (attributes) ->
    super attributes
    @creditCard = new CreditCard(attributes.creditCard)

exports.Transaction = Transaction
