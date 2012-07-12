{AttributeSetter} = require('./attribute_setter')
{CreditCard} = require('./credit_card')

class Customer extends AttributeSetter
  constructor: (attributes) ->
    super attributes
    @creditCards = (new CreditCard(cardAttributes) for cardAttributes in attributes.creditCards)

exports.Customer = Customer
