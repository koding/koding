kd        = require 'kd'
React     = require 'kd-react'
ReactDOM  = require 'react-dom'
Constants = require './constants'

module.exports = (Component) ->

  return class ScrollableContent extends React.Component

    componentDidMount: ->

      window.addEventListener "resize", @bound 'onWindowResize'


    componentWillUpdate: ->

      @prevScrollParams = @getScrollParams()


    componentDidUpdate: ->

      @scrollToBottom()  if @shouldScrollToBottom @prevScrollParams


    componentWillUnmount: ->

      window.removeEventListener 'resize', @bound 'onWindowResize'


    onWindowResize: ->

      @scrollToBottom()  if @shouldScrollToBottom @getScrollParams()


    getScrollParams: ->

      scroller  = @refs.content.getScroller()
      container = ReactDOM.findDOMNode scroller

      { scrollTop, offsetHeight, scrollHeight } = container

      return { scrollTop, offsetHeight, scrollHeight }


    shouldScrollToBottom: (scrollParams) ->

      { AUTO_SCROLL_BOTTOM_INDENT } = Constants
      { scrollTop, offsetHeight, scrollHeight } = scrollParams

      return scrollHeight - (scrollTop + offsetHeight) < AUTO_SCROLL_BOTTOM_INDENT


    scrollToBottom: ->

      scroller  = @refs.content.getScroller()
      container = ReactDOM.findDOMNode scroller

      container.scrollTop = container.scrollHeight


    keepPosition: ->

      { scrollTop, scrollHeight } = @prevScrollParams

      scroller  = @refs.content.getScroller()
      container = ReactDOM.findDOMNode scroller

      container.scrollTop = scrollTop + (container.scrollHeight - scrollHeight)


    _update: -> @refs.content.getScroller()._update()


    scrollTo: (scrollTop) ->

      scroller  = @refs.content.getScroller()
      container = ReactDOM.findDOMNode scroller

      container.scrollTop = scrollTop


    render: ->

      <Component ref='content' {...@props} />

