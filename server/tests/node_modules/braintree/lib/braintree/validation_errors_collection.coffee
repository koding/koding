{Util} = require('./util')
{ValidationError} = require('./validation_error')

class ValidationErrorsCollection
  constructor: (errorAttributes) ->
    @validationErrors = {}
    @errorCollections = {}

    for key, val of errorAttributes
      if key is 'errors'
        @buildErrors(val)
      else
        @errorCollections[key] = new ValidationErrorsCollection(val)

  buildErrors: (errors) ->
    for item in errors
      key = Util.toCamelCase(item.attribute)
      @validationErrors[key] or= []
      @validationErrors[key].push(new ValidationError(item))

  deepErrors: ->
    errors = []

    for key, val of @validationErrors
      errors = errors.concat(val)

    for key, val of @errorCollections
      errors = errors.concat(val.deepErrors())

    errors

  for: (name) ->
    @errorCollections[name]

  forIndex: (index) ->
    @errorCollections["index#{index}"]

  on: (name) ->
    @validationErrors[name]

exports.ValidationErrorsCollection = ValidationErrorsCollection
