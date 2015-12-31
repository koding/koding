kd                   = require 'kd'
_                    = require 'lodash'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
$                    = require 'jquery'
AutoSizeTextarea     = require 'app/components/common/autosizetextarea'
DropboxContainer     = require 'activity/components/dropbox/dropboxcontainer'
EmojiSelectBox       = require 'activity/components/emojiselectbox'
ActivityFlux         = require 'activity/flux'
ChatInputFlux        = require 'activity/flux/chatinput'
KDReactorMixin       = require 'app/flux/base/reactormixin'
formatEmojiName      = require 'activity/util/formatEmojiName'
KeyboardKeys         = require 'app/util/keyboardKeys'
Link                 = require 'app/components/common/link'
helpers              = require './helpers'
focusOnGlobalKeyDown = require 'activity/util/focusOnGlobalKeyDown'
parseStringToCommand = require 'activity/util/parseStringToCommand'

module.exports = class ChatInputWidget extends React.Component

  { TAB, ESC, ENTER, UP_ARROW, RIGHT_ARROW, DOWN_ARROW, LEFT_ARROW } = KeyboardKeys

  @propTypes =
    onReady     : React.PropTypes.func
    onResize    : React.PropTypes.func
    placeholder : React.PropTypes.string
    onChange    : React.PropTypes.func
    tokens      : React.PropTypes.array


  @defaultProps =
    onReady     : kd.noop
    onResize    : kd.noop
    placeholder : ''
    onChange    : kd.noop
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

    textInput = ReactDOM.findDOMNode this.refs.textInput
    focusOnGlobalKeyDown textInput

    window.addEventListener 'resize', @bound 'updateDropboxPositions'

    scrollContainer = $(textInput).closest '.Scrollable'
    scrollContainer.on 'scroll', @bound 'closeDropboxes'

    # Mark as ready if no value is provided in props.
    # Otherwise, we need to wait till value prop is set to state
    @ready()  unless value


  componentDidUpdate: (oldProps, oldState) ->

    isValueChanged = oldState.value isnt @state.value
    if isValueChanged
      @focus()

      { tokens } = @props
      textInput  = ReactDOM.findDOMNode this.refs.textInput
      position   = helpers.getCursorPosition textInput
      ChatInputFlux.actions.dropbox.checkForQuery @stateId, @state.value, position, tokens

    @updateDropboxPositions()

    # This line actually is needed for the case
    # when value prop is set to state.
    # In other cases ready() does nothing
    @ready()  if isValueChanged


  componentWillUnmount: ->

    window.removeEventListener 'resize', @bound 'updateDropboxPositions'

    textInput = ReactDOM.findDOMNode this.refs.textInput
    scrollContainer = $(textInput).closest '.Scrollable'
    scrollContainer.off 'scroll', @bound 'closeDropboxes'


  ready: ->

    return  if @isReady

    @isReady = yes
    @props.onReady?()


  updateDropboxPositions: ->

    textInput = $ ReactDOM.findDOMNode @refs.textInput

    offset = textInput.offset()
    width  = textInput.outerWidth()
    height = textInput.outerHeight()

    inputDimensions = { width, height, left : offset.left, top : offset.top }
    @refs.dropbox.updatePosition inputDimensions
    @refs.emojiSelectBox.updatePosition inputDimensions


  setValue: (value, skipChangeEvent) ->

    return  if @state.value is value

    { channelId, onChange } = @props
    ChatInputFlux.actions.value.setValue channelId, @stateId, value

    onChange value  unless skipChangeEvent


  resetValue: ->

    { channelId } = @props
    ChatInputFlux.actions.value.resetValue channelId, @stateId


  getValue: -> @state.value


  onChange: (event) ->

    { value } = event.target

    @setValue value
    @props.onResize()


  onKeyDown: (event) ->

    switch event.which
      when ENTER       then @onEnter event
      when ESC         then @onEsc event
      when RIGHT_ARROW then @onNextPosition event, { isRightArrow : yes }
      when DOWN_ARROW  then @onNextPosition event, { isDownArrow : yes }
      when TAB         then @onNextPosition event, { isTab : yes }
      when LEFT_ARROW  then @onPrevPosition event, { isLeftArrow : yes }
      when UP_ARROW    then @onPrevPosition event, { isUpArrow : yes }


  onEnter: (event) ->

    return  if event.shiftKey

    kd.utils.stopDOMEvent event

    return @confirmSelectedItem()  if @state.dropboxConfig

    value = @state.value.trim()
    command = parseStringToCommand value

    if command
      @props.onCommand? { command }
    else
      @props.onSubmit? { value }

    @resetValue()


  onEsc: (event) -> @props.onEsc?()


  onNextPosition: (event, keyInfo) ->

    { dropboxConfig } = @state
    return  unless dropboxConfig

    hasHorizontalNavigation = dropboxConfig.get 'horizontalNavigation'
    return @onDropboxClose()  if keyInfo.isRightArrow and not hasHorizontalNavigation

    ChatInputFlux.actions.dropbox.moveToNextIndex @stateId
    kd.utils.stopDOMEvent event


  onPrevPosition: (event, keyInfo) ->

    # it returns to navigate between channels with 'alt+up' keys
    return  if event.altKey and keyInfo.isUpArrow

    if event.target.value
      { dropboxConfig } = @state
      return  unless dropboxConfig

      hasHorizontalNavigation = dropboxConfig.get 'horizontalNavigation'
      return @onDropboxClose()  if keyInfo.isLeftArrow and not hasHorizontalNavigation

      ChatInputFlux.actions.dropbox.moveToPrevIndex @stateId
      kd.utils.stopDOMEvent event
    else

      return  unless keyInfo.isUpArrow

      kd.utils.stopDOMEvent event
      ChatInputFlux.actions.message.setLastMessageEditMode()


  onItemSelected: (index) ->

    ChatInputFlux.actions.dropbox.setSelectedIndex @stateId, index


  onDropboxClose: ->

    ChatInputFlux.actions.dropbox.reset @stateId  if @state.dropboxConfig


  confirmSelectedItem: ->

    { dropboxQuery, dropboxConfig } = @state
    return  unless dropboxConfig

    selectedItem      = @state[dropboxConfig.getIn ['getters', 'selectedItem']]
    confirationResult = dropboxConfig.get('handleItemConfirmation') selectedItem, dropboxQuery

    @onDropboxClose()
    return  unless typeof confirationResult is 'string'

    textInput = ReactDOM.findDOMNode @refs.textInput

    { value, cursorPosition } = helpers.insertDropboxItem textInput, confirationResult
    @setValue value

    kd.utils.defer ->
      helpers.setCursorPosition textInput, cursorPosition


  onEmojiSelectBoxItemConfirmed: (item) ->

    { value } = @state

    newValue = value + formatEmojiName item
    @setValue newValue

    @focus()


  setCommand: (value) ->

    @setValue value


  handleEmojiButtonClick: (event) ->

    ChatInputFlux.actions.emoji.setSelectBoxVisibility @stateId, yes


  focus: ->

    textInput = ReactDOM.findDOMNode @refs.textInput
    textInput.focus()


  closeDropboxes: ->

    @refs.emojiSelectBox?.close()
    @onDropboxClose()


  isLastItemBeingEdited: ->

    chatItems = document.querySelectorAll '.ChatItem'

    return no  unless chatItems.length

    lastItem = chatItems[chatItems.length - 1]

    return lastItem.firstChild.className.indexOf('editing') > -1


  onResize: ->

    ChatPaneBody    = document.querySelector '.Pane-body'
    scrollContainer = ChatPaneBody.querySelector '.Scrollable'

    { scrollTop, scrollHeight } = scrollContainer

    if @isLastItemBeingEdited()
      scrollContainer.scrollTop = scrollContainer.scrollHeight

    @props.onResize()


  renderEmojiSelectBox: ->

    { emojiSelectBoxItems, emojiSelectBoxTabs, emojiSelectBoxQuery } = @state
    { emojiSelectBoxVisibility, emojiSelectBoxSelectedItem, emojiSelectBoxTabIndex } = @state

    <EmojiSelectBox
      items           = { emojiSelectBoxItems }
      tabs            = { emojiSelectBoxTabs }
      query           = { emojiSelectBoxQuery }
      visible         = { emojiSelectBoxVisibility }
      selectedItem    = { emojiSelectBoxSelectedItem }
      tabIndex        = { emojiSelectBoxTabIndex }
      onItemConfirmed = { @bound 'onEmojiSelectBoxItemConfirmed' }
      ref             = 'emojiSelectBox'
      stateId         = { @stateId }
    />


  renderDropbox: ->

    props = _.assign {}, @state, {
      onItemSelected  : @bound 'onItemSelected'
      onItemConfirmed : @bound 'confirmSelectedItem'
    }

    <DropboxContainer ref='dropbox' {...props} />


  render: ->


    <div className={kd.utils.curry "ChatInputWidget", @props.className}>
      { @renderDropbox() }
      { @renderEmojiSelectBox() }
      <AutoSizeTextarea
        ref           = 'textInput'
        placeholder   = @props.placeholder
        value         = { @state.value }
        onChange      = { @bound 'onChange' }
        onKeyDown     = { @bound 'onKeyDown' }
        onResize      = { @bound 'onResize' }
      />
      <Link
        className = "ChatInputWidget-emojiButton"
        onClick   = { @bound 'handleEmojiButtonClick' }
      />
    </div>


React.Component.include.call ChatInputWidget, [KDReactorMixin]

