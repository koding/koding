React    = require 'kd-react'
ReactDOM = require 'react-dom'

module.exports = ScrollerMixin =

  componentWillUpdate: ->

    @shouldScrollToBottom = @shouldScrollBottom()


  shouldScrollBottom: ->

    return  unless @refs?.scrollContainer

    { @scrollTop, offsetHeight, @scrollHeight } = ReactDOM.findDOMNode @refs.scrollContainer

    # we can not catch 0px to scroll to bottom. If scroll near about 100px or less
    # and when new message received we make scroll to bottom so user can see new messages.
    # If not probably user is reading old messages and we don't make scroll to bottom.

    return @scrollHeight - (@scrollTop + offsetHeight) < 10


  componentDidUpdate: ->

    @beforeScrollDidUpdate?()

    return  unless @refs?.scrollContainer

    element = ReactDOM.findDOMNode @refs.scrollContainer
    if @shouldScrollToBottom
      element.scrollTop = element.scrollHeight
    else if @isThresholdReached
      element.scrollTop = @scrollTop + (element.scrollHeight - @scrollHeight)

    @isThresholdReached = no

    @afterScrollDidUpdate?()


  setScrollPosition: ->

    return  unless @refs?.scrollContainer

    scrollContainer = ReactDOM.findDOMNode @refs.scrollContainer

    if @shouldScrollBottom()
      scrollContainer.scrollTop = scrollContainer.scrollHeight


  componentDidMount: ->

    window.addEventListener "resize", @bound 'setScrollPosition'


  componentWillUnmount: ->

    window.removeEventListener "resize", @bound 'setScrollPosition'

