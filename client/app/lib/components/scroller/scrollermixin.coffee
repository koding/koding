React          = require 'kd-react'
scrollToTarget = require 'activity/util/scrollToTarget'


module.exports = ScrollerMixin =

  componentWillUpdate: ->

    return  unless @refs?.scrollContainer

    { @scrollTop, offsetHeight, @scrollHeight } = React.findDOMNode @refs.scrollContainer
    @shouldScrollToBottom = @scrollTop + offsetHeight is @scrollHeight


  componentDidUpdate: ->

    return  unless @refs?.scrollContainer

    element = React.findDOMNode @refs.scrollContainer

    if @shouldScrollToBottom
      element.scrollTop = element.scrollHeight
    else
      element.scrollTop = @scrollTop + (element.scrollHeight - @scrollHeight)

