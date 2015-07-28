kd       = require 'kd'
React    = require 'kd-react'
TextArea = require 'react-autosize-textarea'
EmojiDropup = require 'activity/components/emojidropup'

ActivityFlux   = require 'activity/flux'
KDReactorMixin = require 'app/flux/reactormixin'

module.exports = class ChatInputWidget extends React.Component

  ENTER = 13

  constructor: (props) ->

    super props

    @state = { value : '' }


  getDataBindings: ->

    { getters } = ActivityFlux

    return {
      emojis        : getters.currentEmojis
      selectedEmoji : getters.selectedEmoji
    }


  componentDidUpdate: (prevProps, prevState) ->

    { selectedEmoji } = @state
    return  if prevState.selectedEmoji is selectedEmoji
    return  unless selectedEmoji

    domElement = React.findDOMNode(this)
    textarea   = domElement.querySelector 'textarea'

    textBeforeCursor = helper.getTextBeforeCursor textarea
    lastWord         = helper.getLastWord textBeforeCursor

    startIndex = textBeforeCursor.lastIndexOf lastWord
    endIndex   = textarea.selectionStart

    value    = textarea.value
    newValue = value.substring(0, startIndex) + ":#{selectedEmoji}:"
    newValue += value.substring endIndex

    @setState { value : newValue }

  update: (event) ->

    value = event.target.value
    @setState { value }

    emoji = @findEmojiInText()
    ActivityFlux.actions.emoji.setQuery emoji ? ''


  findEmojiInText: ->

    domElement = React.findDOMNode(this)
    textarea   = domElement.querySelector 'textarea'

    textBeforeCursor = helper.getTextBeforeCursor textarea
    lastWord         = helper.getLastWord textBeforeCursor

    matchResult = lastWord.match /\:(.+)/
    return matchResult?[1]


  onKeyDown: (event) ->

    if event.which is ENTER and not event.shiftKey
      kd.utils.stopDOMEvent event
      @props.onSubmit? { value: @state.value }

      @setState { value: '' }


  onResize: ->

    console.log 'resized'


  render: ->

    { emojis, selectedEmoji } = @state

    <div className="ChatInputWidget">
      <EmojiDropup emojis={emojis} selectedEmoji={selectedEmoji} />
      <TextArea
        value     = { @state.value }
        onChange  = { @bound 'update' }
        onKeyDown = { @bound 'onKeyDown' }
        onResize  = { @bound 'onResize' }
      />
    </div>


  helper =

    getTextBeforeCursor: (textbox) ->

      position = textbox.selectionStart
      value    = textbox.value

      return value.substring 0, position


    getLastWord: (str) ->

      matchResult = str.match /\s([^\s]+)$/
      return matchResult?[1] ? str


React.Component.include.call ChatInputWidget, [KDReactorMixin]