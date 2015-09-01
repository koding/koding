_  = require 'lodash'
kd = require 'kd'

###
 * This module is modified version of nuclear-js reactor mixin module.
 * It directly uses kd.singletons.reactor rather than accepting a reactor.
###
module.exports =

  getInitialState: ->

    @id = kd.utils.getUniqueId()  unless @id
    getState kd.singletons.reactor, @getDataBindings(), @id


  componentDidMount: ->

    component = this
    { reactor } = kd.singletons

    bindings = component.getDataBindings()
    id       = component.id

    state = _.assign component.state, getState(reactor, bindings, id)
    component.__unwatchFns = []

    _.each bindings, (getter, key) ->
      getter = processGetter getter, id
      unwatchFn = reactor.observe getter, (val) ->
        newState = {}
        newState[key] = val
        component.setState newState
      component.__unwatchFns.push unwatchFn


  componentWillUnmount: ->

    component = this
    while component.__unwatchFns.length
      component.__unwatchFns.shift()()


###*
 * Returns a mapping of the getDataBinding keys to
 * the reactor values
###
getState = (reactor, data, id) ->

  return _.mapValues data, (value) -> reactor.evaluate processGetter(value, id)


processGetter = (getter, id) ->

  if typeof getter is 'function'
    return getter id
  return getter