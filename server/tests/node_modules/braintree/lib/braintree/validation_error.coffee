class ValidationError
  constructor: (error) ->
    @attribute = error.attribute
    @code = error.code
    @message = error.message

exports.ValidationError = ValidationError
