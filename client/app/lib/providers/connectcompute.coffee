React = require 'app/react'
kd = require 'kd'
{ isFunction } = require 'lodash'

debug = require('debug')('compute:connect')

# FIXME: so naive, but works for now.
makeSingular = (plural) -> plural.slice 0, -1


makeState = (config, props) ->

  unless config.storage
    console.warn \
      'You need to specify the requirements via `storage` config option.'
    return {}

  { storage } = kd.singletons.computeController

  state = config.storage.reduce (acc, pluralName) ->
    singularName = makeSingular pluralName
    # if we pass stackId, machineId or templateId our wrapped component will
    # receive a prop named stack, machine, template.
    if resourceId = props["#{singularName}Id"]
      acc[singularName] = storage.get(pluralName, '_id', resourceId)

    # no matter what, return the full resource just incase the component
    # wants to use all items for some calculation.
    acc[pluralName] = storage.get(pluralName)

    return acc
  , {}

  # allow a final props transition to be made by passing a transformState
  # function to config.
  if isFunction config.transformState
    state = config.transformState state, props

  return Object.assign({}, state, props)


module.exports = connectCompute = (config) -> (WrappedComponent) ->

  class ConnectCompute extends React.Component

    constructor: (props) ->
      super props

      @handlers = null
      @events = {}
      @_mounted = no

      @state = makeState config, props


    onStorageUpdate: ->

      return  unless @_mounted

      debug 'onStorageUpdate'

      @setState makeState config, @props


    componentDidMount: ->

      @_mounted = yes

      { computeController } = kd.singletons

      computeController.storage.on 'change', @bound 'onStorageUpdate'

      { controllerEvents } = config

      return  unless controllerEvents

      Object.keys(controllerEvents).forEach (resource) =>
        return  unless resourceId = @props["#{resource}Id"]

        handlers = controllerEvents[resource]
        Object.keys(handlers).forEach (eventName) =>
          eventId = "#{eventName}-#{resourceId}"
          return  if @events[eventId]

          @events[eventId] = (event) =>
            return  if event.status is 'NotInitialized' and @state.percentage
            newState = handlers[eventName](event)
            @setState newState

          computeController.on eventId, @events[eventId]


    componentWillReceiveProps: (nextProps, nextState) ->

      @setState makeState config, nextProps


    componentWillUnmount: ->

      @_mounted = no

      { computeController } = kd.singletons

      computeController.storage.off 'change', @bound 'onStorageUpdate'

      debug 'componentWillUnmount'

      Object.keys(@events).forEach (eventId) =>
        computeController.off eventId, @events[eventId]
        delete @events[eventId]

    render: ->
      <WrappedComponent {...@state} />

  name = \
    WrappedComponent.displayName or WrappedComponent.name or 'Component'

  ConnectCompute.displayName = "ConnectCompute(#{name})"

  return ConnectCompute
