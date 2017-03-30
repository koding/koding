React = require 'app/react'
kd = require 'kd'

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

  return Object.assign({}, state, props)


module.exports = connectCompute = (config) -> (WrappedComponent) ->

  class ConnectedCompute extends React.Component

    constructor: (props) ->
      super props

      @handlers = null
      @events = {}
      @_mounted = no

      @state = makeState config, props


    onStorageUpdate: ->

      return  unless @_mounted


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
            newState = handlers[eventName](event)
            @setState newState

          computeController.on eventId, @events[eventId]


    componentWillUnmount: ->

      @_mounted = no

      { computeController } = kd.singletons

      computeController.storage.off 'change', @bound 'onStorageUpdate'

      Object.keys(@events).forEach (eventId) =>
        computeController.off eventId, @events[eventId]
        delete @events[eventId]

    render: ->
      <WrappedComponent {...@state} />
