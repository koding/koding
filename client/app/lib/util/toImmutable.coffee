immutable = require 'immutable'

module.exports = toImmutable = (js) ->

  return js  if typeof js isnt 'object'
  return js  if js is null

  seq = immutable.Seq(js).map(toImmutable)

  return if immutable.Iterable.isIndexed seq
  then seq.toList()
  else seq.toMap()
