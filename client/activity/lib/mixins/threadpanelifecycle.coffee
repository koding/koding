React        = require 'kd-react'
ActivityFlux = require 'activity/flux'

componentDidMount = (reset) ->

  reset @props, @state, =>
    scrollTop              = @state.channelThread.getIn [ 'flags', 'scrollPosition' ]
    scroller               = React.findDOMNode @refs.pane.refs.chatPane.refs.scrollContainer
    scroller.scrollTop     = scrollTop  if scrollTop
    scroller.style.opacity = 1


componentWillReceiveProps = (reset, nextProps) -> reset nextProps, @state


componentWillUnmount = ->

  # terrifying drill - SY
  scroller            = React.findDOMNode @refs.pane.refs.chatPane.refs.scrollContainer
  { scrollTop }       = scroller
  { channel, thread } = ActivityFlux.actions

  scroller.style.opacity = 0
  channel.setScrollPosition (@state.channelThread.getIn [ 'channel', 'id' ]), scrollTop
  thread.changeSelectedThread null


module.exports = threadPaneMount = {
  componentDidMount
  componentWillReceiveProps
  componentWillUnmount
}
