_  = require 'lodash'
kd = require 'kd'

###
 * This module is modified version of nuclear-js reactor mixin module.
 * It directly uses kd.singletons.reactor rather than accepting a reactor.
###
module.exports =

  getInitialState: ->

    @stateId = kd.utils.getUniqueId()  unless @stateId
    getState kd.singletons.reactor, @getDataBindings()


  componentDidMount: ->

    component = this
    { reactor } = kd.singletons

    bindings = component.getDataBindings()

    state = _.assign component.state, getState(reactor, bindings)
    component.__unwatchFns = []

    _.each bindings, (getter, key) ->
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
getState = (reactor, data) ->

  return _.mapValues data, (value) -> reactor.evaluate value
