kd              = require 'kd'
React           = require 'kd-react'
TextArea        = require 'react-autosize-textarea'
EmojiDropup     = require 'activity/components/emojidropup'
EmojiSelector   = require 'activity/components/emojiselector'
ActivityFlux    = require 'activity/flux'
KDReactorMixin  = require 'app/flux/reactormixin'
formatEmojiName = require 'activity/util/formatEmojiName'
Link            = require 'app/components/common/link'
helpers         = require './helpers'

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
      commonEmojiList               : getters.commonEmojiList
      commonEmojiListFlags          : getters.commonEmojiListFlags
      commonEmojiListSelectedItem   : getters.commonEmojiListSelectedItem
    }


  handleEmojiSelectorItemConfirmed: ->

    { commonEmojiListSelectedItem, value } = @state

    newValue = value + formatEmojiName commonEmojiListSelectedItem
    @setState { value : newValue }

    textInput = React.findDOMNode this.refs.textInput
    textInput.focus()

    ActivityFlux.actions.emoji.resetCommonListFlags()


  handleEmojiDropupItemConfirmed: ->

    { filteredEmojiListSelectedItem } = @state

    textInput = React.findDOMNode this.refs.textInput

    { value, cursorPosition } = helpers.insertEmoji textInput, filteredEmojiListSelectedItem
    @setState { value }

    ActivityFlux.actions.emoji.unsetFilteredListQuery()
    kd.utils.defer ->
      helpers.setCursorPosition textInput, cursorPosition


  onValueChanged: (event) ->

    value = event.target.value
    @setState { value }

    textInput = React.findDOMNode this.refs.textInput

    emojiQuery = helpers.getEmojiQuery textInput
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
          @handleEmojiDropupItemConfirmed()
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


  renderEmojiDropup: ->

    { filteredEmojiList, filteredEmojiListSelectedItem, filteredEmojiListQuery } = @state

    <EmojiDropup
      emojis          = { filteredEmojiList }
      selectedEmoji   = { filteredEmojiListSelectedItem }
      emojiQuery      = { filteredEmojiListQuery }
      onItemConfirmed = { @bound 'handleEmojiDropupItemConfirmed' }
    />


  renderEmojiSelector: ->

    { commonEmojiList, commonEmojiListFlags, commonEmojiListSelectedItem } = @state

    <EmojiSelector
      emojis          = { commonEmojiList }
      visible         = { commonEmojiListFlags.get 'visible' }
      selectedEmoji   = { commonEmojiListSelectedItem }
      onItemConfirmed = { @bound 'handleEmojiSelectorItemConfirmed' }
    />


  render: ->


    <div className="ChatInputWidget">
      { @renderEmojiDropup() }
      { @renderEmojiSelector() }
      <TextArea
        value     = { @state.value }
        onChange  = { @bound 'onValueChanged' }
        onKeyDown = { @bound 'onKeyDown' }
        ref       = "textInput"
      />
      <Link
        className = "ChatInputWidget-emojiButton"
        onClick   = { @bound 'handleEmojiButtonClick' }
      />
    </div>


React.Component.include.call ChatInputWidget, [KDReactorMixin]