kd                   = require 'kd'
React                = require 'kd-react'
classnames           = require 'classnames'
getEmbedType         = require 'app/util/getEmbedType'
EmbedBoxImage        = require 'activity/components/embedboximage'
EmbedBoxVideo        = require 'activity/components/embedboxvideo'
EmbedBoxObject       = require 'activity/components/embedboxobject'
EmbedBoxLinkDisplay  = require 'activity/components/embedboxlinkdisplay'
ImmutableRenderMixin = require 'react-immutable-render-mixin'

module.exports = class EmbedBox extends React.Component

  @include [ImmutableRenderMixin]


  @defaultProps =
    data : null
    type : ''


  renderEmbedBoxImage: ->

    { data, type } = @props
    if data.link_embed.images?.length > 0
      <EmbedBoxImage data={data} type={type} />


  renderEmbedBoxObject: ->

    { data } = @props
    <EmbedBoxObject data={data} />


  renderEmbedBoxLinkDisplay: ->

    { data } = @props
    <EmbedBoxLinkDisplay data={data} />


  renderEmbedBoxVideo: ->

    { data } = @props
    <EmbedBoxVideo data={data} />


  renderEmbedBoxContent: (embedType) ->

    switch embedType
      when 'image'  then @renderEmbedBoxImage()
      when 'object' then @renderEmbedBoxObject()
      when 'video'  then @renderEmbedBoxVideo()
      else               @renderEmbedBoxLinkDisplay()


  render: ->

    { data, type } = @props
    return null  unless data and data.link_embed

    { link_embed } = data

    embedType = getEmbedType link_embed.media?.type or link_embed.type or 'link'

    isInvalidType   = embedType is 'link' and not link_embed.description
    isInvalidType or= embedType is 'error'
    return null  if isInvalidType

    <div className='EmbedBox-container clearfix'>
      { @renderEmbedBoxContent embedType }
    </div>
