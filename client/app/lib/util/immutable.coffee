Immutable = require 'seamless-immutable'

module.exports = immutable = (obj) ->
  Immutable obj, { prototype: Object.getPrototypeOf obj }
