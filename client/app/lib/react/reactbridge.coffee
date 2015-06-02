React = require 'app/react'

module.exports = class ReactBridge extends React.Component

  constructor: (props) ->

    unless props.dispatcher
      throw new Error "#{@constructor.name}: requires a dispatcher."

    super props

    @state = { component: @props.component or null }

    @setComponent = @setComponent.bind this


  componentDidMount: ->

    # register to dispatcher, show the emitted component when
    # `ShowComponent` event is dispatched.
    @props.dispatcher.on 'SetComponent', @setComponent


  componentWillUnmount: ->

    @props.dispatcher.off 'SetComponent', @setComponent


  ###
   * Set component to the state, this will trigger the rerender.
  ###
  setComponent: (component) -> @setState { component }


  ###*
   * Custom getter for component. If you want to do funny stuff with the given
   * component this is the place.
   *
   * @return {React.Component} _component
  ###
  getComponent: -> @state.component


  render: ->
    <div className="js-bridgeContainer">{@getComponent()}</div>


