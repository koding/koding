kd      = require 'kd'
React   = require 'kd-react'
Encoder = require 'htmlencode'

module.exports = class EmbedBoxLinkContent extends React.Component

  @defaultProps =
    data : {}


  renderTitle: ->

    { link_url, link_embed } = @props.data

    title = link_embed.title or link_url
    <a href={link_url} target='_blank' className='EmbedBoxLinkContent-title'>
      { title }
    </a>


  renderDescription: ->

    { link_url, link_embed } = @props.data

    description = if link_embed.description?
    then "#{Encoder.XSSEncode(link_embed.description).substring 0, 128}..."
    else ''

    <a href={link_url} target='_blank' className='EmbedBoxLinkContent-description'>
      { description }
    </a>
    

  renderProvider: ->

    { link_url, link_embed } = @props.data

    provider = link_embed.provider_name or ''
    <a href={link_url} target='_blank' className='EmbedBoxLinkContent-provider'>
      <strong>{ provider }</strong>
    </a>


  render: ->

    <div className='EmbedBoxLinkContent'>
      { @renderTitle() }
      { @renderDescription() }
      { @renderProvider() }
    </div>

