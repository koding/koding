traverse  = require 'traverse'

module.exports.create = (KONFIG) ->
  conf = {}
  travis = traverse(KONFIG)
  travis.paths().forEach (path) -> conf["KONFIG_#{path.join("_")}".toUpperCase()] = travis.get(path) unless typeof travis.get(path) is 'object'
  return conf
