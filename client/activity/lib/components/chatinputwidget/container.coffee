kd                   = require 'kd'
_                    = require 'lodash'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
ChatInputFlux        = require 'activity/flux/chatinput'
KDReactorMixin       = require 'app/flux/base/reactormixin'
helpers              = require './helpers'
parseStringToCommand = require 'activity/util/parseStringToCommand'
ChatInputWidget      = require './index'
formatEmojiName      = require 'activity/util/formatEmojiName'

module.exports = class ChatInputContainer extends React.Component

  @propTypes =
    onReady     : React.PropTypes.func
    onChange    : React.PropTypes.func
    onSubmit    : React.PropTypes.func
    onCommand   : React.PropTypes.func
    onEsc       : React.PropTypes.func
    onResize    : React.PropTypes.func
    tokens      : React.PropTypes.array


  @defaultProps =
    onReady     : kd.noop
    onChange    : kd.noop
    onCommand   : kd.noop
    onSubmit    : kd.noop
    onEsc       : kd.noop
    onResize    : kd.noop
    tokens      : []


  getDataBindings: ->

    { getters } = ChatInputFlux

    return {
      value                      : getters.currentValue @stateId

      emojiSelectBoxItems        : getters.emojiSelectBoxItems @stateId
      emojiSelectBoxTabs         : getters.emojiSelectBoxTabs
      emojiSelectBoxQuery        : getters.emojiSelectBoxQuery @stateId
      emojiSelectBoxSelectedItem : getters.emojiSelectBoxSelectedItem @stateId
      emojiSelectBoxVisibility   : getters.emojiSelectBoxVisibility @stateId
      emojiSelectBoxTabIndex     : getters.emojiSelectBoxTabIndex @stateId

      dropboxQuery               : getters.dropboxQuery @stateId
      dropboxConfig              : getters.dropboxConfig @stateId

      dropboxChannels            : getters.dropboxChannels @stateId
      channelsSelectedIndex      : getters.channelsSelectedIndex @stateId
      channelsSelectedItem       : getters.channelsSelectedItem @stateId

      dropboxEmojis              : getters.dropboxEmojis @stateId
      emojisSelectedIndex        : getters.emojisSelectedIndex @stateId
      emojisSelectedItem         : getters.emojisSelectedItem @stateId

      dropboxMentions            : getters.dropboxMentions @stateId
      mentionsSelectedIndex      : getters.mentionsSelectedIndex @stateId
      mentionsSelectedItem       : getters.mentionsSelectedItem @stateId

      dropboxSearchItems         : getters.dropboxSearchItems @stateId
      searchSelectedIndex        : getters.searchSelectedIndex @stateId
      searchSelectedItem         : getters.searchSelectedItem @stateId
      searchFlags                : getters.searchFlags @stateId

      dropboxCommands            : getters.dropboxCommands @stateId
      commandsSelectedIndex      : getters.commandsSelectedIndex @stateId
      commandsSelectedItem       : getters.commandsSelectedItem @stateId
    }


  componentDidMount: ->

    { value } = @props
    @setValue value, yes  if value

    # Mark as ready if no value is provided in props.
    # Otherwise, we need to wait till value prop is set to state
    @ready()  unless value


  componentDidUpdate: (oldProps, oldState) ->

    isValueChanged = oldState.value isnt @state.value

    # This line actually is needed for the case
    # when value prop is set to state.
    # In other cases ready() does nothing
    @ready()  if isValueChanged


  ready: ->

    return  if @isReady

    @isReady = yes
    @props.onReady?()


  setValue: (value, skipChangeEvent) ->

    return  if @state.value is value

    { channelId, onChange } = @props
    ChatInputFlux.actions.value.setValue channelId, @stateId, value

    kd.utils.defer @bound 'checkForQuery'

    onChange value  unless skipChangeEvent


  checkForQuery: ->

    return  unless @refs.input

    { dropbox } = ChatInputFlux.actions
    position    = @refs.input.getCursorPosition()
    dropbox.checkForQuery @stateId, @state.value, position, @props.tokens


  getValue: -> @state.value


  setCommand: (value) -> @setValue value


  focus: -> @refs.input.focus()


  onEnter: (event) ->

    return  if event.shiftKey

    kd.utils.stopDOMEvent event

    return @onDropboxItemConfirmed()  if @state.dropboxConfig

    value = @state.value.trim()
    command = parseStringToCommand value

    if command
      @props.onCommand? { command }
    else
      @props.onSubmit? { value }

      @setValue ''


  onRightArrow: (event) ->

    { dropboxConfig } = @state
    return  unless dropboxConfig
    return @onDropboxClose()  unless dropboxConfig.get 'horizontalNavigation'

    @moveToNextDropboxIndex()
    kd.utils.stopDOMEvent event


  onDownArrow: (event) ->

    { dropboxConfig } = @state
    return  unless dropboxConfig

    @moveToNextDropboxIndex()
    kd.utils.stopDOMEvent event


  onTab: (event) -> @onDownArrow event


  onLeftArrow: (event) ->

    { dropboxConfig } = @state
    return  unless dropboxConfig
    return @onDropboxClose()  unless dropboxConfig.get 'horizontalNavigation'

    @moveToPrevDropboxIndex()
    kd.utils.stopDOMEvent event


  onUpArrow: (event) ->

    # it returns to navigate between channels with 'alt+up' keys
    return  if event.altKey

    if event.target.value
      { dropboxConfig } = @state
      return  unless dropboxConfig

      @moveToPrevDropboxIndex()
      kd.utils.stopDOMEvent event
    else
      ChatInputFlux.actions.message.setLastMessageEditMode()
      kd.utils.stopDOMEvent event


  moveToNextDropboxIndex: ->

    ChatInputFlux.actions.dropbox.moveToNextIndex @stateId


  moveToPrevDropboxIndex: ->

    ChatInputFlux.actions.dropbox.moveToPrevIndex @stateId


  onDropboxItemSelected: (index) ->

    ChatInputFlux.actions.dropbox.setSelectedIndex @stateId, index


  onDropboxClose: ->

    ChatInputFlux.actions.dropbox.reset @stateId  if @state.dropboxConfig


  onDropboxItemConfirmed: ->

    { dropboxQuery, dropboxConfig } = @state
    return  unless dropboxConfig

    selectedItem      = @state[dropboxConfig.getIn ['getters', 'selectedItem']]
    confirationResult = dropboxConfig.get('handleItemConfirmation') selectedItem, dropboxQuery

    @onDropboxClose()
    return  unless typeof confirationResult is 'string'

    position = @refs.input.getCursorPosition()
    { newValue, newPosition } = helpers.replaceWordAtPosition @state.value, position, confirationResult

    @setValue newValue

    kd.utils.defer =>
      @refs.input.setCursorPosition newPosition


  onSelectBoxVisible: ->

    ChatInputFlux.actions.emoji.setSelectBoxVisibility @stateId, yes


  onSelectBoxItemSelected: (index) ->

    ChatInputFlux.actions.emoji.setSelectBoxSelectedIndex @stateId, index


  onSelectBoxItemUnselected: ->

    ChatInputFlux.actions.emoji.resetSelectBoxSelectedIndex @stateId


  onSelectBoxItemConfirmed: ->

    { emojiSelectBoxSelectedItem, value } = @state

    ChatInputFlux.actions.emoji.incrementUsageCount emojiSelectBoxSelectedItem

    newValue = value + formatEmojiName emojiSelectBoxSelectedItem
    @setValue newValue

    @onSelectBoxClose()


  onSelectBoxTabChange: (tabIndex) ->

    ChatInputFlux.actions.emoji.unsetSelectBoxQuery @stateId
    ChatInputFlux.actions.emoji.setSelectBoxTabIndex @stateId, tabIndex


  onSelectBoxClose: ->

    ChatInputFlux.actions.emoji.setSelectBoxVisibility @stateId, no


  onSelectBoxSearch: (value) ->

    ChatInputFlux.actions.emoji.setSelectBoxQuery @stateId, value


  render: ->

    <ChatInputWidget
      ref                       = 'input'
      className                 = { @props.className }
      data                      = { @state }
      placeholder               = { @props.placeholder }
      onResize                  = { @props.onResize }
      onChange                  = { @bound 'setValue' }
      onEnter                   = { @bound 'onEnter' }
      onEsc                     = { @props.onEsc }
      onRightArrow              = { @bound 'onRightArrow' }
      onDownArrow               = { @bound 'onDownArrow' }
      onTab                     = { @bound 'onTab' }
      onLeftArrow               = { @bound 'onLeftArrow' }
      onUpArrow                 = { @bound 'onUpArrow' }
      onDropboxItemSelected     = { @bound 'onDropboxItemSelected' }
      onDropboxItemConfirmed    = { @bound 'onDropboxItemConfirmed' }
      onDropboxClose            = { @bound 'onDropboxClose' }
      onSelectBoxVisible        = { @bound 'onSelectBoxVisible' }
      onSelectBoxItemSelected   = { @bound 'onSelectBoxItemSelected' }
      onSelectBoxItemUnselected = { @bound 'onSelectBoxItemUnselected' }
      onSelectBoxItemConfirmed  = { @bound 'onSelectBoxItemConfirmed' }
      onSelectBoxTabChange      = { @bound 'onSelectBoxTabChange' }
      onSelectBoxClose          = { @bound 'onSelectBoxClose' }
      onSelectBoxSearch         = { @bound 'onSelectBoxSearch' }
    />


React.Component.include.call ChatInputContainer, [ KDReactorMixin ]

