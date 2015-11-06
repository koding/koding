kd           = require 'kd'
React        = require 'kd-react'
proxifyUrl   = require 'app/util/proxifyUrl'
getEmbedSize = require 'activity/util/getEmbedSize'

module.exports = class EmbedBoxImage extends React.Component

  @defaultProps =
    data : null
    type : ''


  getImageSize: (item) ->

    { link_embed } = @props.data
    image          = link_embed.images.first

    return getEmbedSize image


  getImageStyle: ->

    { width, height } = @getImageSize()

    return style =
      height : "#{height}px"
      width  : "#{width}px"


  renderImage: ->

    { link_embed } = @props.data
    { width }      = @getImageSize()

    srcUrl = proxifyUrl link_embed.images.first.url, { width }

    <img
      src   = { srcUrl }
      title = { link_embed.title ? '' }
      style = { @getImageStyle() }
    />


  render: ->

    { data } = @props

    return null  unless data

    <a href={data.link_url} target='_blank' className='EmbedBoxImage' style={@getImageStyle()}>
      { @renderImage() }
    </a>

