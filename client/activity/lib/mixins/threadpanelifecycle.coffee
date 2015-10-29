React        = require 'kd-react'
ActivityFlux = require 'activity/flux'

###*
 * Mixin to handle pane lifecycle events.
 *
 * @param {function(props, state)} reset
 * @return {Object} Mixin
###
module.exports = ThreadPaneLifecycleMixin = (reset) ->

  componentDidMount = ->

    reset @props, @state, =>
      scrollTop              = @state.channelThread.getIn [ 'flags', 'scrollPosition' ]
      scroller               = React.findDOMNode @refs.pane.refs.chatPane.refs.scrollContainer
      scroller.scrollTop     = scrollTop  if scrollTop
      scroller.style.opacity = 1


  componentWillReceiveProps = (nextProps) -> reset nextProps, @state


  componentWillUnmount = ->

    # terrifying drill - SY
    scroller            = React.findDOMNode @refs.pane.refs.chatPane.refs.scrollContainer
    { scrollTop }       = scroller
    { channel, thread } = ActivityFlux.actions

    scroller.style.opacity = 0
    channel.setScrollPosition (@state.channelThread.getIn [ 'channel', 'id' ]), scrollTop
    thread.changeSelectedThread null


  return {
    componentDidMount
    componentWillReceiveProps
    componentWillUnmount
  }
