React        = require 'kd-react'
Encoder      = require 'htmlencode'
getEmbedSize = require 'activity/util/getEmbedSize'

module.exports = class EmbedBoxVideo extends React.Component

  getVideoSize: ->

    { link_embed }    = @props.data
    { media }         = link_embed

    # protect against old data
    return { width: 0, height: 0 }  unless media
    return getEmbedSize media

  getVideoStyle: ->

    { width, height } = @getVideoSize()

    return style =
      height : "#{height}px"
      width  : "#{width}px"


  componentDidMount: ->

    element   = React.findDOMNode @refs.video
    { media } = @props.data.link_embed
    return  unless media

    { html }  = media
    return  unless html

    { width, height } = @getVideoSize()

    div           = document.createElement 'div'
    div.innerHTML = Encoder.htmlDecode html
    iframe        = div.firstChild

    div.removeChild iframe

    iframe.setAttribute 'height', height
    iframe.setAttribute 'width', width

    element.appendChild iframe


  render: ->

    <figure className='EmbedBoxVideo' ref='video' style={@getVideoStyle()} />
