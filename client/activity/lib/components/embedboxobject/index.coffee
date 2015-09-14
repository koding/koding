kd      = require 'kd'
React   = require 'kd-react'
Encoder = require 'htmlencode'

module.exports = class EmbedBoxObject extends React.Component

  @defaultProps =
    data : {}


  render: ->

    { link_embed } = @props.data

    objectHtml = link_embed.object?.html
    <div className='EmbedBoxObject'>
      { Encoder.htmlDecode objectHtml or '' }
    </div>

