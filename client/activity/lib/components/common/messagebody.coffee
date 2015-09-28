$             = require 'jquery'
React         = require 'kd-react'
emojify       = require 'emojify.js'
formatContent = require 'app/util/formatReactivityContent'
immutable     = require 'immutable'


module.exports = class MessageBody extends React.Component

  @defaultProps =
    message: immutable.Map()


  renderEmojis: ->

    contentElement = React.findDOMNode @content
    emojify.run contentElement  if contentElement


  contentDidMount: (content) ->

    @content = content
    @renderEmojis()


  componentDidUpdate: -> @renderEmojis()


  render: ->

    content = formatContent @props.message.get 'body'

    return \
      <article
        className="MessageBody"
        ref={@bound 'contentDidMount'}
        dangerouslySetInnerHTML={__html: content} />

