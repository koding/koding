profileHelper = require 'app/components/profile/helper'
###*
 * Since browserify doesn't let us require modules dynamically with variables,
 * components should be exported here. Until we find a better solution, if you
 * want your component to be reachable via `/Showcase` route you will have to
 * register it here.
###
module.exports = ComponentRegistry =
  common:
    example:
      component : require 'app/components/common/example'
      type      : 'react'

    timeago:
      component : require 'app/components/common/timeago'
      type      : 'react'
      props     : {from: null}

  profile:
    avatar:
      component : require 'app/components/profile/avatar'
      type      : 'react'
      props     : account: require('app/util/whoami')()

  get: (collection, component) ->

    _component = this[collection]?[component]

    return _component or null


