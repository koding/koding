kd                   = require 'kd'
React                = require 'kd-react'
classnames           = require 'classnames'
getEmbedType         = require 'app/util/getEmbedType'
EmbedBoxImage        = require 'activity/components/embedboximage'
EmbedBoxObject       = require 'activity/components/embedboxobject'
EmbedBoxLinkDisplay  = require 'activity/components/embedboxlinkdisplay'
ImmutableRenderMixin = require 'react-immutable-render-mixin'

module.exports = class EmbedBox extends React.Component

  @include [ImmutableRenderMixin]


  @defaultProps =
    data : {}


  renderEmbedBoxImage: ->

    { data } = @props
    if data.getIn(['link_embed', 'images'])?.length > 0
      <EmbedBoxImage data={data} />
    else
      <span className='hidden' />


  renderEmbedBoxObject: ->

    { data } = @props
    <EmbedBoxObject data={data} />


  renderEmbedBoxLinkDisplay: ->

    { data } = @props
    <EmbedBoxLinkDisplay data={data} />


  renderEmbedBoxContent: (type) ->

    switch type
      when 'image'  then @renderEmbedBoxImage()
      when 'object' then @renderEmbedBoxObject()
      else               @renderEmbedBoxLinkDisplay()


  render: ->

    { link_embed } = @props.data

    type = getEmbedType link_embed.type or 'link'

    isInvalidType   = type is 'link' and not link_embed.description
    isInvalidType or= type in ['video', 'image']
    return <span className='hidden' />  if isInvalidType

    <div className='EmbedBox-container clearfix'>
      { @renderEmbedBoxContent type }
    </div>

