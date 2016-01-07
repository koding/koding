immutable = require 'immutable'

module.exports = toImmutable = (js) ->

  return js  if typeof js isnt 'object'

  seq = immutable.Seq(js).map(toImmutable)

  return if immutable.Iterable.isIndexed seq
  then seq.toList()
  else seq.toMap()
