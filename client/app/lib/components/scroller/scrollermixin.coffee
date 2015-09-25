React          = require 'kd-react'
scrollToTarget = require 'activity/util/scrollToTarget'

module.exports = ScrollerMixin =

  componentWillUpdate: ->

    @shouldScrollToBottom = @getScrollToBottomFlag()


  getScrollToBottomFlag: ->

    return  unless @refs?.scrollContainer
    { @scrollTop, offsetHeight, @scrollHeight } = React.findDOMNode @refs.scrollContainer
    @scrollHeight - (@scrollTop + offsetHeight) < 100


  componentDidUpdate: ->

    return  unless @refs?.scrollContainer

    element = React.findDOMNode @refs.scrollContainer

    if @shouldScrollToBottom
      element.scrollTop = element.scrollHeight
    else
      element.scrollTop = @scrollTop + (element.scrollHeight - @scrollHeight)


  setScrollPosition: ->

    return  unless @refs?.scrollContainer

    scrollContainer = React.findDOMNode @refs.scrollContainer

    if @getScrollToBottomFlag()
      scrollContainer.scrollTop = scrollContainer.scrollHeight


  componentDidMount: ->

    window.addEventListener "resize", @bound 'setScrollPosition'


  componentWillUnmount: ->

    window.removeEventListener "resize", @bound 'setScrollPosition'

