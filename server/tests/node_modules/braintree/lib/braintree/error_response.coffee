{Transaction} = require('./transaction')
{ValidationErrorsCollection} = require('./validation_errors_collection')

class ErrorResponse
  constructor: (attributes) ->
    for key, value of attributes
      @[key] = value
    @success = false
    @errors = new ValidationErrorsCollection(attributes.errors)
    @transaction = new Transaction(attributes.transaction) if attributes.transaction

exports.ErrorResponse = ErrorResponse
