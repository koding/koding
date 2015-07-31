kd              = require 'kd'
React           = require 'kd-react'
TextArea        = require 'react-autosize-textarea'
EmojiDropup     = require 'activity/components/emojidropup'
EmojiSelector   = require 'activity/components/emojiselector'
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
      filteredEmojiList             : getters.filteredEmojiList
      filteredEmojiListSelectedItem : getters.filteredEmojiListSelectedItem
      filteredEmojiListQuery        : getters.filteredEmojiListQuery
      filteredEmojiListFlags        : getters.filteredEmojiListFlags
      commonEmojiList               : getters.commonEmojiList
      commonEmojiListFlags          : getters.commonEmojiListFlags
      commonEmojiListSelectedItem   : getters.commonEmojiListSelectedItem
    }


  componentDidUpdate: (prevProps, prevState) ->

    isHandled = @insertFilteredEmojiIfNeed prevProps, prevState
    isHandled = @insertCommonEmojiIfNeed prevProps, prevState  unless isHandled


  insertCommonEmojiIfNeed: (prevProps, prevState) ->

    { commonEmojiListFlags, commonEmojiListSelectedItem, value } = @state
    return no  if prevState.commonEmojiListFlags is commonEmojiListFlags
    return no  unless commonEmojiListFlags.get 'selectionConfirmed'

    newValue = value + formatEmojiName commonEmojiListSelectedItem
    @setState { value : newValue }

    textInput = React.findDOMNode this.refs.textInput
    textInput.focus()

    kd.utils.defer ->
      ActivityFlux.actions.emoji.resetCommonListFlags()

    return yes


  insertFilteredEmojiIfNeed: (prevProps, prevState) ->

    { filteredEmojiListSelectedItem, filteredEmojiListFlags } = @state
    return no  if prevState.filteredEmojiListFlags is filteredEmojiListFlags
    return no  unless filteredEmojiListFlags.get 'selectionConfirmed'

    textInput = React.findDOMNode this.refs.textInput

    { value, cursorPosition } = helper.insertEmoji textInput, filteredEmojiListSelectedItem
    @setState { value }

    emojiActions = ActivityFlux.actions.emoji
    kd.utils.defer ->
      helper.setCursorPosition textInput, cursorPosition
      emojiActions.resetFilteredListFlags()
      emojiActions.unsetFilteredListQuery()

    return yes


  onValueChanged: (event) ->

    value = event.target.value
    @setState { value }

    textInput = React.findDOMNode this.refs.textInput

    emojiQuery = helper.getEmojiQuery textInput
    ActivityFlux.actions.emoji.setFilteredListQuery emojiQuery


  onKeyDown: (event) ->

    { filteredEmojiList : { size } } = @state
    emojiActions  = ActivityFlux.actions.emoji
    isEmojiMode   = size > 0
    isSingleEmoji = size is 1

    switch event.which
      when ENTER
        return  if event.shiftKey

        kd.utils.stopDOMEvent event
        if isEmojiMode
          emojiActions.confirmFilteredListSelection()
        else
          @props.onSubmit? { value: @state.value }
          @setState { value: '' }

      when ESC
        emojiActions.unsetFilteredListQuery()

      when RIGHT_ARROW, DOWN_ARROW, TAB
        if isSingleEmoji
          emojiActions.unsetFilteredListQuery()
        else if isEmojiMode
          kd.utils.stopDOMEvent event
          emojiActions.moveToNextFilteredListIndex()

      when LEFT_ARROW, UP_ARROW
        if isSingleEmoji
          emojiActions.unsetFilteredListQuery()
        else if isEmojiMode
          kd.utils.stopDOMEvent event
          emojiActions.moveToPrevFilteredListIndex()


  handleEmojiButtonClick: (event) ->

    ActivityFlux.actions.emoji.setCommonListVisibility yes


  render: ->

    { filteredEmojiList, filteredEmojiListSelectedItem, filteredEmojiListQuery } = @state
    { commonEmojiList, commonEmojiListFlags, commonEmojiListSelectedItem } = @state

    <div className="ChatInputWidget">
      <EmojiDropup
        emojis        = { filteredEmojiList }
        selectedEmoji = { filteredEmojiListSelectedItem }
        emojiQuery    = { filteredEmojiListQuery }
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
        onClick   = { @bound 'handleEmojiButtonClick' }
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