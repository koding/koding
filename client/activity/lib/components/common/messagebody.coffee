$                    = require 'jquery'
React                = require 'kd-react'
emojify              = require 'emojify.js'
formatContent        = require 'app/util/formatContent'
immutable            = require 'immutable'


module.exports = class MessageBody extends React.Component

  @defaultProps =
    message: immutable.Map()


  contentDidMount: (content) ->

    contentElement = React.findDOMNode content
    emojify.run contentElement  if contentElement


  render: ->

    options = { tags : { useReactivityUrl : yes } }
    content = formatContent @props.message.get('body'), options

    return \
      <article
        className="MessageBody"
        ref={@bound 'contentDidMount'}
        dangerouslySetInnerHTML={__html: content} />


