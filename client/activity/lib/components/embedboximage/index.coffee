kd             = require 'kd'
React          = require 'kd-react'
ReactDOM       = require 'react-dom'
proxifyUrl     = require 'app/util/proxifyUrl'
getEmbedSize   = require 'activity/util/getEmbedSize'
eventEmitter   = require 'app/mixins/eventemitter'
resizeListener = require 'app/mixins/resizelistener'

module.exports = class EmbedBoxImage extends React.Component

  @defaultProps =
    data   : null
    type   : ''
    width  : 0
    height : 0

  constructor: ->

    super

    @state = @getImageSize()


  componentDidMount: -> @_windowDidResize()


  getImageSize: (item) ->

    { link_embed } = @props.data
    image          = link_embed.images.first

    return getEmbedSize image


  getImageStyle: ->

    { width, height } = @state

    return style =
      height : "#{height}px"
      width  : "#{width}px"


  _getParentNodeWidth: ->

    { parentNode } = ReactDOM.findDOMNode @refs.link
    style          = window.getComputedStyle parentNode
    width          = parseInt (style.getPropertyValue 'width'), 10

    return width


  _windowDidResize: ->

    image = @props.data.link_embed.images.first
    sizes = getEmbedSize image, @_getParentNodeWidth()

    @setState sizes


  renderImage: ->

    { link_embed } = @props.data
    { width }      = @getImageSize()

    srcUrl = proxifyUrl link_embed.images.first.url, { width }

    <img
      src   = { srcUrl }
      title = { link_embed.title ? '' }
    />


  render: ->

    { data } = @props

    return null  unless data

    <a ref='link' href={data.link_url} target='_blank' className='EmbedBoxImage' style={@getImageStyle()}>
      { @renderImage() }
    </a>

EmbedBoxImage.include [ resizeListener, eventEmitter ]