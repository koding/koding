React        = require 'kd-react'
ActivityFlux = require 'activity/flux'

###*
 * Mixin to handle pane lifecycle events.
 *
 * @param {function(props, state)} reset
 * @return {Object} Mixin
###
module.exports = ThreadPaneLifecycleMixin = (reset) ->

  componentDidMount = -> reset @props, @state

  componentWillReceiveProps = (nextProps) -> reset nextProps, @state

  componentWillUnmount = ->

    { thread } = ActivityFlux.actions

    thread.changeSelectedThread null


  return {
    componentDidMount
    componentWillReceiveProps
    componentWillUnmount
  }


