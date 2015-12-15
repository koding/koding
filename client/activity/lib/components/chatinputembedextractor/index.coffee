kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
ChatInputWidget      = require 'activity/components/chatinputwidget'
urlGrabber           = require 'app/util/urlGrabber'
ActivityFlux         = require 'activity/flux'
embedlyHelpers       = require 'activity/flux/helpers/embedly'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class ChatInputEmbedExtractor extends React.Component

  componentDidMount: ->

    { value }    = @props
    @previousUrl = embedlyHelpers.extractUrl value
    @timer       = null


  onChange: (value) ->

    kd.utils.killWait @timer  if @timer
    url = embedlyHelpers.extractUrl value

    if url is @previousUrl or not url
      @editEmbedPayload url
    else
      @timer = kd.utils.wait 1000, @lazyBound 'editEmbedPayload', url

    @previousUrl = url


  editEmbedPayload: (url) ->

    ActivityFlux.actions.message.editEmbedPayloadByUrl @props.messageId, url


  focus: -> @refs.input.focus()


  getValue: -> @refs.input.getValue()


  render: ->

    <ChatInputWidget ref='input' {...@props} onChange={@bound 'onChange'} />


ChatInputEmbedExtractor.include [ ImmutableRenderMixin ]

