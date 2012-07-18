class AttributeSetter
  constructor: (attributes) ->
    for key, value of attributes
      @[key] = value

exports.AttributeSetter = AttributeSetter
