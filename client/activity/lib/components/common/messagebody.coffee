React         = require 'kd-react'
formatContent = require 'app/util/formatContent'

module.exports = class MessageBody extends React.Component

  render: ->
    <article dangerouslySetInnerHTML={__html: formatContent @props.source} />
