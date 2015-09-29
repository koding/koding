kd      = require 'kd'
React   = require 'kd-react'
Encoder = require 'htmlencode'

module.exports = class EmbedBoxLinkContent extends React.Component

  @defaultProps =
    data : null


  renderTitle: ->

    { link_url, link_embed } = @props.data

    title = link_embed.title or link_url
    <a href={link_url} target='_blank' className='EmbedBoxLinkContent-title'>
      { title }
    </a>


  encodeString: (str) ->

    p = document.createElement "p"
    p.textContent = str;
    return p.innerHTML


  renderDescription: ->

    { link_url, link_embed } = @props.data

    description = ''

    if typeof link_embed.description is 'string'
      description = "#{@encodeString(link_embed.description).substring 0, 128}..."

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

    { data } = @props
    return null  unless data

    <div className='EmbedBoxLinkContent'>
      { @renderTitle() }
      { @renderDescription() }
      { @renderProvider() }
    </div>

