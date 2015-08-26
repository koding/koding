React         = require 'kd-react'
emojify       = require 'emojify.js'
formatContent = require 'app/util/formatContent'

module.exports = class MessageBody extends React.Component

  componentDidMount: ->

    MessageContent = React.findDOMNode this.refs.MessageContent
    emojify.run MessageContent  if MessageContent


  render: ->
    <article ref="MessageContent" dangerouslySetInnerHTML={__html: formatContent @props.source} />
