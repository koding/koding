kd         = require 'kd'
React      = require 'kd-react'
proxifyUrl = require 'app/util/proxifyUrl'

module.exports = class EmbedBoxImage extends React.Component

  @defaultProps =
    data : {}


  renderImage: ->

    { link_embed } = @props.data

    srcUrl = proxifyUrl link_embed.images?[0]?.url, { width : 200 }

    <img
      src   = { srcUrl }
      title = { link_embed.title ? '' }
      width = '100%'
    />


  render: ->

    { link_url } = @props.data

    <a href={link_url ? '#'} target='_blank' className='EmbedBoxImage'>
      { @renderImage() }
    </a>

