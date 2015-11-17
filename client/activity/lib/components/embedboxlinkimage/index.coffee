kd         = require 'kd'
React      = require 'kd-react'
ReactDOM   = require 'react-dom'
proxifyUrl = require 'app/util/proxifyUrl'

module.exports = class EmbedBoxLinkImage extends React.Component

  @defaultProps =
    data   : null
    width  : 100
    height : 100
    crop   : yes
    grow   : yes


  handleError: ->

    image = ReactDOM.findDOMNode @refs.image
    image.className = 'hidden'


  render: ->

    { data, width, height, crop, grow } = @props
    return null  unless data

    { link_url, link_embed } = data

    imageOptions = { width, height, crop, grow }
    srcUrl       = proxifyUrl link_embed.images?[0]?.url, imageOptions
    altText      = link_embed.title
    altText     += if link_embed.author_name then " by #{link_embed.author_name}" else ''

    <a href={link_url} target='_blank' className='EmbedBoxLinkImage'>
      <img
        src       = { srcUrl }
        alt       = { altText }
        title     = { altText }
        ref       = 'image'
        onError   = { @bound 'handleError' }
      />
    </a>

