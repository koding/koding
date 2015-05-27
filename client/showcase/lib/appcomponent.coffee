React = require 'react'
kd = require 'kd'

module.exports = class ShowcaseAppComponent extends React.Component

  constructor: (props) ->

    super props

    @state = { component: <h3>{'HelloWorld'}</h3> }

    @showComponent = @showComponent.bind this


  componentDidMount: ->

    # register to dispatcher, show the emitted component when
    # `ShowComponent` event is dispatched.
    @props.dispatcher.on 'ShowComponent', @showComponent


  componentWillUnmount: ->

    @props.dispatcher.off 'ShowComponent', @showComponent


  ###
   * Set component to the state, this will trigger the rerender.
  ###
  showComponent: (component) -> @setState { component }


  ###*
   * Custom getter for component. If you want to do funny stuff with the given
   * component this is the place.
   *
   * @return {React.Component} _component
  ###
  getComponent: -> <span>{@state.component}</span>


  render: ->
    <div>{@getComponent()}</div>


