{AttributeSetter} = require('./attribute_setter')
{Transaction} = require('./transaction')

class Subscription extends AttributeSetter
  constructor: (attributes) ->
    super attributes
    @transactions = (new Transaction(transactionAttributes) for transactionAttributes in attributes.transactions)

exports.Subscription = Subscription
