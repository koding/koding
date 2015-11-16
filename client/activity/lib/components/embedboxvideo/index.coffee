kd             = require 'kd'
React          = require 'kd-react'
ReactDOM       = require 'react-dom'
Encoder        = require 'htmlencode'
getEmbedSize   = require 'activity/util/getEmbedSize'
eventEmitter   = require 'app/mixins/eventemitter'
resizeListener = require 'app/mixins/resizelistener'

module.exports = class EmbedBoxVideo extends React.Component

  @defaultProps =
    width  : 0
    height : 0

  constructor: ->

    super

    @state = @getVideoSize()


  getVideoSize: ->

    { link_embed } = @props.data
    { media }      = link_embed

    # protect against old data
    return { width: 0, height: 0 }  unless media
    return getEmbedSize media


  getVideoStyle: ->

    { width, height } = @state

    return style =
      height : "#{height}px"
      width  : "#{width}px"


  componentDidMount: ->

    element   = ReactDOM.findDOMNode @refs.video
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
    @_windowDidResize()


  _getParentNodeWidth: ->

    { parentNode } = ReactDOM.findDOMNode @refs.video
    style          = window.getComputedStyle parentNode
    width          = parseInt (style.getPropertyValue 'width'), 10

    return width


  _windowDidResize: ->

    { media } = @props.data.link_embed
    sizes     = getEmbedSize media, @_getParentNodeWidth()

    @setState sizes


  render: ->

    <figure className='EmbedBoxVideo' ref='video' style={@getVideoStyle()} />

EmbedBoxVideo.include [ resizeListener, eventEmitter ]
