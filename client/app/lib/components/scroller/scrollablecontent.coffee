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


    getScroller: -> @refs.content.refs.scroller


    getScrollParams: ->

      container = ReactDOM.findDOMNode @getScroller()

      { scrollTop, offsetHeight, scrollHeight } = container

      return { scrollTop, offsetHeight, scrollHeight }


    shouldScrollToBottom: (scrollParams) ->

      { AUTO_SCROLL_BOTTOM_INDENT } = Constants
      { scrollTop, offsetHeight, scrollHeight } = scrollParams

      return scrollHeight - (scrollTop + offsetHeight) < AUTO_SCROLL_BOTTOM_INDENT


    scrollToBottom: ->

      container = ReactDOM.findDOMNode @getScroller()

      container.scrollTop = container.scrollHeight


    keepPosition: ->

      { scrollTop, scrollHeight } = @prevScrollParams

      container = ReactDOM.findDOMNode @getScroller()

      container.scrollTop = scrollTop + (container.scrollHeight - scrollHeight)


    scrollToPosition: (scrollTop) ->

      container = ReactDOM.findDOMNode @getScroller()

      container.scrollTop = scrollTop


    render: ->

      <Component ref='content' {...@props} />

