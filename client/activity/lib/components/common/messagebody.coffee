React         = require 'kd-react'
formatContent = require 'app/util/formatContent'
emojify               = require 'emojify.js'


module.exports = class MessageBody extends React.Component

  componentDidMount: ->

    MessageContent = React.findDOMNode this.refs.MessageContent
    emojify.run MessageContent  if MessageContent


  render: ->
    <article ref="MessageContent" dangerouslySetInnerHTML={__html: formatContent @props.source} />
