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

    url = embedlyHelpers.extractUrl value

    # if url is not changed and it is already processed, do nothing
    return  if url is @previousUrl and not @timer

    kd.utils.killWait @timer  if @timer
    @timer = null

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

    <ChatInputWidget.Container ref='input' {...@props} onChange={@bound 'onChange'} />


ChatInputEmbedExtractor.include [ ImmutableRenderMixin ]
