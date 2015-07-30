kd       = require 'kd'
React    = require 'kd-react'
TextArea = require 'react-autosize-textarea'
EmojiDropup   = require 'activity/components/emojidropup'
EmojiSelector = require 'activity/components/emojiselector'

ActivityFlux    = require 'activity/flux'
KDReactorMixin  = require 'app/flux/reactormixin'
formatEmojiName = require 'activity/util/formatEmojiName'

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
      emojis                      : getters.currentEmojis
      selectedEmoji               : getters.selectedEmoji
      emojiQuery                  : getters.currentEmojiQuery
      commonEmojiList             : getters.commonEmojiList
      commonEmojiListFlags        : getters.commonEmojiListFlags
      commonEmojiListSelectedItem : getters.commonEmojiListSelectedItem
    }


  componentDidUpdate: (prevProps, prevState) ->

    isHandled = @insertFilteredEmojiIfNeed prevProps, prevState
    isHandled = @insertCommonEmojiIfNeed prevProps, prevState  unless isHandled


  insertCommonEmojiIfNeed: (prevProps, prevState) ->

    { commonEmojiListFlags, commonEmojiListSelectedItem, value } = @state
    return no  if prevState.commonEmojiListFlags is commonEmojiListFlags
    return no  unless commonEmojiListFlags.get 'selectionCompleted'

    newValue = value + formatEmojiName commonEmojiListSelectedItem
    @setState { value : newValue }

    textInput = React.findDOMNode this.refs.textInput
    textInput.focus()

    kd.utils.defer ->
      ActivityFlux.actions.emoji.resetCommonListFlags()

    return yes


  insertFilteredEmojiIfNeed: (prevProps, prevState) ->

    { selectedEmoji } = @state
    return no  if prevState.selectedEmoji is selectedEmoji
    return no  unless selectedEmoji.get 'confirmed'

    textInput = React.findDOMNode this.refs.textInput

    { value, cursorPosition } = helper.insertEmoji textInput, selectedEmoji.get 'emoji'
    @setState { value }

    kd.utils.defer ->
      helper.setCursorPosition textInput, cursorPosition

    return yes


  onValueChanged: (event) ->

    value = event.target.value
    @setState { value }

    textInput = React.findDOMNode this.refs.textInput

    emojiQuery = helper.getEmojiQuery textInput
    ActivityFlux.actions.emoji.setEmojiQuery emojiQuery


  onKeyDown: (event) ->

    { emojis : { size } } = @state
    emojiActions  = ActivityFlux.actions.emoji
    isEmojiMode   = size > 0
    isSingleEmoji = size is 1

    switch event.which
      when ENTER
        return  if event.shiftKey
        if isEmojiMode
          emojiActions.confirmSelectedEmoji()
        else
          kd.utils.stopDOMEvent event
          @props.onSubmit? { value: @state.value }
          @setState { value: '' }

      when ESC
        emojiActions.unsetEmojiQuery()

      when RIGHT_ARROW, DOWN_ARROW, TAB
        if isSingleEmoji
          emojiActions.clearEmojiQuery()
        else if isEmojiMode
          kd.utils.stopDOMEvent event
          emojiActions.moveToNextEmoji()

      when LEFT_ARROW, UP_ARROW
        if isSingleEmoji
          emojiActions.clearEmojiQuery()
        else if isEmojiMode
          kd.utils.stopDOMEvent event
          emojiActions.moveToPrevEmoji()


  handleEmojiIconClick: (event) ->

    ActivityFlux.actions.emoji.setCommonListVisibility yes


  render: ->

    { emojis, selectedEmoji, emojiQuery } = @state
    { commonEmojiList, commonEmojiListFlags, commonEmojiListSelectedItem } = @state

    <div className="ChatInputWidget">
      <EmojiDropup
        emojis        = { emojis }
        selectedEmoji = { selectedEmoji }
        emojiQuery    = { emojiQuery }
      />
      <EmojiSelector
        emojis        = { commonEmojiList }
        visible       = { commonEmojiListFlags.get 'visible' }
        selectedEmoji = { commonEmojiListSelectedItem }
      />
      <TextArea
        value     = { @state.value }
        onChange  = { @bound 'onValueChanged' }
        onKeyDown = { @bound 'onKeyDown' }
        ref       = "textInput"
      />
      <a
        href      = "#"
        className = "ChatInputWidget-emojiButton"
        onClick   = { @bound 'handleEmojiIconClick' }
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


    getEmojiQuery: (textInput) ->

      textBeforeCursor = helper.getTextBeforeCursor textInput
      lastWord         = helper.getLastWord textBeforeCursor

      matchResult = lastWord?.match /^\:(.+)/
      return matchResult?[1]


    insertEmoji: (textInput, emoji) ->

      textBeforeCursor  = helper.getTextBeforeCursor textInput
      textToReplace     = helper.getLastWord textBeforeCursor
      startReplaceIndex = textBeforeCursor.lastIndexOf textToReplace
      endReplaceIndex   = helper.getCursorPosition textInput

      value             = textInput.value
      textBeforeCursor  = value.substring(0, startReplaceIndex)
      textBeforeCursor += formatEmojiName(emoji) + " "
      cursorPosition    = textBeforeCursor.length
      newValue          = textBeforeCursor + value.substring endReplaceIndex

      return { value : newValue, cursorPosition }


React.Component.include.call ChatInputWidget, [KDReactorMixin]