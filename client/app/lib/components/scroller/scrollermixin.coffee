React           = require 'kd-react'
ReactDOM        = require 'react-dom'
scrollerActions = require './scrolleractions'

module.exports = ScrollerMixin =

  componentDidMount: ->

    @scrollerAction = null
    window.addEventListener "resize", @bound 'onWindowResize'


  componentWillUpdate: ->

    { SCROLL_TO_BOTTOM } = scrollerActions
    @scrollerAction = SCROLL_TO_BOTTOM  if @shouldScrollToBottom()


  componentDidUpdate: ->

    @beforeScrollDidUpdate?()

    @performScrollerAction @scrollerAction
    @scrollerAction = null

    @afterScrollDidUpdate?()


  componentWillUnmount: ->

    window.removeEventListener "resize", @bound 'onWindowResize'


  shouldScrollToBottom: ->

    return  unless @refs?.scrollContainer

    { @scrollTop, offsetHeight, @scrollHeight } = ReactDOM.findDOMNode @refs.scrollContainer

    # we can not catch 0px to scroll to bottom. If scroll near about 100px or less
    # and when new message received we make scroll to bottom so user can see new messages.
    # If not probably user is reading old messages and we don't make scroll to bottom.

    return @scrollHeight - (@scrollTop + offsetHeight) < 10


  performScrollerAction: (action) ->

    return  unless @refs?.scrollContainer

    { SCROLL_TO_BOTTOM, KEEP_POSITION, UPDATE } = scrollerActions

    element = ReactDOM.findDOMNode @refs.scrollContainer
    switch action
      when SCROLL_TO_BOTTOM
        element.scrollTop = element.scrollHeight
      when KEEP_POSITION
        element.scrollTop = @scrollTop + (element.scrollHeight - @scrollHeight)
      when UPDATE
        @refs.scrollContainer._update()


  onWindowResize: ->

    { SCROLL_TO_BOTTOM } = scrollerActions
    @performScrollerAction SCROLL_TO_BOTTOM  if @shouldScrollToBottom()
