mapping = require '../mapping.json'

###*
 * create dependency graph for given test filename
 *
 * @param {string} name
###

module.exports = (name) ->
  map = {}
  originalReqs = mapping[name]

  dependencies = [name]
  while originalReqs.embedded
    dependency = originalReqs.embedded.name
    dependencies.push dependency
    originalReqs = mapping[dependency]

  dependencies.reverse()
  for dep in dependencies
    map[dep] = mapping[dep]

  map