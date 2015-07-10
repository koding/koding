React         = require 'kd-react'
formatContent = require 'app/util/formatContent'

module.exports = class MessageBody extends React.Component

  render: ->

    <article className="has-markdown" dangerouslySetInnerHTML={__html: @formatSource()} />


  formatSource: -> formatContent @props.source