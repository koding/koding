kd       = require 'kd'
React    = require 'kd-react'
TextArea = require 'react-autosize-textarea'
EmojiDropup = require 'activity/components/emojidropup'

ActivityFlux   = require 'activity/flux'
KDReactorMixin = require 'app/flux/reactormixin'

module.exports = class ChatInputWidget extends React.Component

  TAB         = 9
  ENTER       = 13
  ESC         = 27
  LEFT_ARROW  = 37
  UP_ARROW    = 38
  RIGHT_ARROW = 39
  DOWN_ARROW  = 40

  constructor: (props) ->

    super props

    @state = { value : '' }


  getDataBindings: ->

    { getters } = ActivityFlux

    return {
      emojis        : getters.currentEmojis
      selectedEmoji : getters.selectedEmoji
      emojiQuery    : getters.currentEmojiQuery
    }


  componentDidUpdate: (prevProps, prevState) ->

    { selectedEmoji } = @state
    return  if prevState.selectedEmoji is selectedEmoji
    return  unless selectedEmoji

    textInput = React.findDOMNode(this.refs.textInput)

    { value, cursorPosition } = helper.insertEmoji textInput, selectedEmoji
    @setState { value }

    kd.utils.defer ->
      helper.setCursorPosition textInput, cursorPosition


  onChange: (event) ->

    value = event.target.value
    @setState { value }

    textInput = React.findDOMNode this.refs.textInput

    emojiQuery = helper.getEmojiQuery textInput
    ActivityFlux.actions.emoji.setEmojiQuery emojiQuery


  onKeyDown: (event) ->

    { emojis : { size } } = @state
    emojiActions = ActivityFlux.actions.emoji
    switch event.which
      when ENTER
        if not event.shiftKey
          kd.utils.stopDOMEvent event
          @props.onSubmit? { value: @state.value }
          @setState { value: '' }
      when ESC
        emojiActions.clearEmojiQuery()
      when RIGHT_ARROW, DOWN_ARROW, TAB
        if size is 1
          emojiActions.clearEmojiQuery()
        else if size > 0
          event.preventDefault()
          emojiActions.moveToNextEmoji()
      when LEFT_ARROW, UP_ARROW
        if size is 1
          emojiActions.clearEmojiQuery()
        else if size > 0
          event.preventDefault()
          emojiActions.moveToPrevEmoji()


  onResize: ->

    console.log 'resized'


  render: ->

    { emojis, selectedEmoji, emojiQuery } = @state

    <div className="ChatInputWidget">
      <EmojiDropup emojis={emojis} selectedEmoji={selectedEmoji} emojiQuery={emojiQuery} />
      <TextArea
        value     = { @state.value }
        onChange  = { @bound 'onChange' }
        onKeyDown = { @bound 'onKeyDown' }
        onResize  = { @bound 'onResize' }
        ref       = "textInput"
      />
    </div>


  helper =

    getCursorPosition: (textInput) -> textInput.selectionStart


    setCursorPosition: (textInput, position) ->

      textInput.focus()
      textInput.setSelectionRange position, position


    getTextBeforeCursor: (textInput) ->

      position = helper.getCursorPosition textInput
      value    = textInput.value

      return value.substring 0, position


    getLastWord: (str) ->

      matchResult = str.match /([^\s]+)$/
      return matchResult?[1]


    getLastEmoji: (str) ->

      matchResult = str.match /\s(\:[^\s]+\:\s)$/
      return matchResult?[1]


    getEmojiQuery: (textInput) ->

      textBeforeCursor = helper.getTextBeforeCursor textInput
      lastWord         = helper.getLastWord textBeforeCursor

      matchResult = lastWord?.match /\:(.+)/
      return matchResult?[1]


    insertEmoji: (textInput, emoji) ->

      textBeforeCursor = helper.getTextBeforeCursor textInput
      lastEmoji        = helper.getLastEmoji textBeforeCursor
      textToReplace    = lastEmoji ? helper.getLastWord textBeforeCursor

      startReplaceIndex = textBeforeCursor.lastIndexOf textToReplace
      endReplaceIndex   = helper.getCursorPosition textInput

      value = textInput.value
      textBeforeCursor = value.substring(0, startReplaceIndex) + ":#{emoji}: "
      cursorPosition = textBeforeCursor.length
      newValue = textBeforeCursor + value.substring endReplaceIndex

      return { value : newValue, cursorPosition }


React.Component.include.call ChatInputWidget, [KDReactorMixin]