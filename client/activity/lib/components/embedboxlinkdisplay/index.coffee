kd                      = require 'kd'
React                   = require 'kd-react'
classnames              = require 'classnames'
EmbedBoxLinkContent     = require 'activity/components/embedboxlinkcontent'
EmbedBoxLinkImage       = require 'activity/components/embedboxlinkimage'

module.exports = class EmbedBoxLinkDisplay extends React.Component

  @defaultProps =
    data : null


  render: ->

    { data } = @props
    return null  unless data

    { link_embed } = data

    withImage  = link_embed.images?.length > 0
    classNames = classnames
      'EmbedBoxLinkDisplay' : yes
      'withImage'           : withImage

    <div className={classNames}>
      <EmbedBoxLinkContent data={data} />
      { <EmbedBoxLinkImage data={data} /> if withImage }
    </div>
