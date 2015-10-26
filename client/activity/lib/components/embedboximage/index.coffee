kd         = require 'kd'
React      = require 'kd-react'
proxifyUrl = require 'app/util/proxifyUrl'

module.exports = class EmbedBoxImage extends React.Component

  @defaultProps =
    data : null
    type : ''


  getImageWidth: ->

    { type } = @props

    switch type
      when 'chat'    then 550
      when 'comment' then 400
      else 200


  renderImage: ->

    { link_embed } = @props.data

    srcUrl = proxifyUrl link_embed.images?[0]?.url, { width : @getImageWidth() }

    <img
      src   = { srcUrl }
      title = { link_embed.title ? '' }
      width = '100%'
    />


  render: ->

    { data } = @props
    return null  unless data

    { link_url } = data

    <a href={link_url} target='_blank' className='EmbedBoxImage'>
      { @renderImage() }
    </a>

