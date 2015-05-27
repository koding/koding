###*
 * Since browserify doesn't let us require modules dynamically with variables,
 * components should be exported here. Until we find a better solution, if you
 * want your component to be reachable via `/Showcase` route you will have to
 * register it here.
###
module.exports = ComponentRegistry =
  common:
    example:
      component : require './components/common/example'
      type      : 'react'

  get: (collection, component) ->

    _component = this[collection]?[component]

    return _component or null

