kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
$                    = require 'jquery'
AutoSizeTextarea     = require 'app/components/common/autosizetextarea'
EmojiDropbox         = require 'activity/components/emojidropbox'
ChannelDropbox       = require 'activity/components/channeldropbox'
MentionDropbox       = require 'activity/components/mentiondropbox'
EmojiSelectBox       = require 'activity/components/emojiselectbox'
SearchDropbox        = require 'activity/components/searchdropbox'
CommandDropbox       = require 'activity/components/commanddropbox'
ActivityFlux         = require 'activity/flux'
ChatInputFlux        = require 'activity/flux/chatinput'
KDReactorMixin       = require 'app/flux/base/reactormixin'
formatEmojiName      = require 'activity/util/formatEmojiName'
KeyboardKeys         = require 'app/util/keyboardKeys'
Link                 = require 'app/components/common/link'
helpers              = require './helpers'
focusOnGlobalKeyDown = require 'activity/util/focusOnGlobalKeyDown'
parseStringToCommand = require 'activity/util/parseStringToCommand'
DropboxType          = require 'activity/flux/chatinput/dropboxtype'


module.exports = class ChatInputWidget extends React.Component

  { TAB, ESC, ENTER, UP_ARROW, RIGHT_ARROW, DOWN_ARROW, LEFT_ARROW } = KeyboardKeys

  @defaultProps =
    disabledFeatures : []
    onReady          : kd.noop
    onResize         : kd.noop
    placeholder      : ''
    onChange         : kd.noop


  getDataBindings: ->

    { getters }          = ChatInputFlux
    { disabledFeatures } = @props

    return {
      value                          : getters.currentValue @stateId
      dropboxType                    : getters.dropboxType @stateId
      dropboxQuery                   : getters.dropboxQuery @stateId
      dropboxItems                   : getters.dropboxItems @stateId, disabledFeatures
      dropboxSelectedIndex           : getters.dropboxSelectedIndex @stateId
      dropboxSelectedItem            : getters.dropboxSelectedItem @stateId
      dropboxFormattedSelectedItem   : getters.dropboxFormattedSelectedItem @stateId
    }


  componentDidMount: ->

    { value } = @props
    @setValue value, yes  if value

    textInput = ReactDOM.findDOMNode this.refs.textInput
    focusOnGlobalKeyDown textInput

    window.addEventListener 'resize', @bound 'updateDropboxPosition'

    scrollContainer = $(textInput).closest '.Scrollable'
    scrollContainer.on 'scroll', @bound 'closeDropboxes'

    # Mark as ready if no value is provided in props.
    # Otherwise, we need to wait till value prop is set to state
    @ready()  unless value


  componentDidUpdate: (oldProps, oldState) ->

    isValueChanged = oldState.value isnt @state.value
    @focus()  if isValueChanged
    @updateDropboxPosition()

    # This line actually is needed for the case
    # when value prop is set to state.
    # In other cases ready() does nothing
    @ready()  if isValueChanged


  componentWillUnmount: ->

    window.removeEventListener 'resize', @bound 'updateDropboxPosition'

    textInput = ReactDOM.findDOMNode this.refs.textInput
    scrollContainer = $(textInput).closest '.Scrollable'
    scrollContainer.off 'scroll', @bound 'closeDropboxes'


  ready: ->

    return  if @isReady

    @isReady = yes
    @props.onReady?()


  updateDropboxPosition: ->

    textInput = $ ReactDOM.findDOMNode @refs.textInput

    offset = textInput.offset()
    width  = textInput.outerWidth()
    height = textInput.outerHeight()

    inputDimensions = { width, height, left : offset.left, top : offset.top }
    @refs.dropbox?.updatePosition inputDimensions


  isFeatureDisabled: (feature) -> @props.disabledFeatures.indexOf(feature) > -1


  setValue: (value, skipChangeEvent) ->

    return  if @state.value is value

    { channelId, onChange } = @props
    textInput      = ReactDOM.findDOMNode @refs.textInput
    cursorPosition = helpers.getCursorPosition textInput

    ChatInputFlux.actions.value.setValue channelId, @stateId, value
    ChatInputFlux.actions.dropbox.checkForQuery @stateId, value, cursorPosition

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

    return @confirmSelectedItem()  if @refs.dropbox

    unless isDropboxEnter
      value = @state.value.trim()
      command = parseStringToCommand value

      if command
        @props.onCommand? { command }
      else
        @props.onSubmit? { value }

      @resetValue()


  onEsc: (event) -> @props.onEsc?()


  onNextPosition: (event, keyInfo) ->

    if @refs.dropbox
      ChatInputFlux.actions.dropbox.moveToNextIndex @stateId
      kd.utils.stopDOMEvent event


  onPrevPosition: (event, keyInfo) ->

    if event.target.value
      if @refs.dropbox
        ChatInputFlux.actions.dropbox.moveToPrevIndex @stateId
        kd.utils.stopDOMEvent event
    else

      return  unless keyInfo.isUpArrow

      kd.utils.stopDOMEvent event
      ChatInputFlux.actions.message.setLastMessageEditMode()


  onItemSelected: (index) ->

    ChatInputFlux.actions.dropbox.setSelectedIndex @stateId, index


  onDropboxClose: ->

    ChatInputFlux.actions.dropbox.reset @stateId  if @state.dropboxType


  confirmSelectedItem: ->

    { dropboxFormattedSelectedItem } = @state

    textInput = ReactDOM.findDOMNode @refs.textInput

    { value, cursorPosition } = helpers.insertDropboxItem textInput, dropboxFormattedSelectedItem + ' '
    @setValue value
    @onDropboxClose()

    kd.utils.defer ->
      helpers.setCursorPosition textInput, cursorPosition


  onEmojiSelectBoxItemConfirmed: (item) ->

    { value } = @state

    newValue = value + item
    @setValue newValue

    @focus()


  onSearchItemConfirmed: (message) ->

    { initialChannelId, id } = message
    ActivityFlux.actions.channel.loadChannel(initialChannelId).then ({ channel }) ->
      kd.singletons.router.handleRoute "/Channels/#{channel.name}/#{id}"


  setCommand: (value) ->

    @setValue value


  handleEmojiButtonClick: (event) ->

    ChatInputFlux.actions.emoji.setSelectBoxVisibility @stateId, yes


  focus: ->

    textInput = ReactDOM.findDOMNode @refs.textInput
    textInput.focus()


  closeDropboxes: ->

    @refs.emojiSelectBox.close()
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


  renderDropbox: ->

    { dropboxType, dropboxQuery, dropboxItems, dropboxSelectedIndex, dropboxSelectedItem } = @state

    Component = switch dropboxType
      when DropboxType.EMOJI then EmojiDropbox
      when DropboxType.CHANNEL then ChannelDropbox
      when DropboxType.MENTION then MentionDropbox
      when DropboxType.SEARCH then SearchDropbox
      when DropboxType.COMMAND then CommandDropbox

    return  unless Component

    <Component
      ref             = 'dropbox'
      query           = { dropboxQuery }
      items           = { dropboxItems }
      selectedIndex   = { dropboxSelectedIndex }
      selectedItem    = { dropboxSelectedItem }
      onItemSelected  = { @bound 'onItemSelected' }
      onItemConfirmed = { @bound 'confirmSelectedItem' }
      onClose         = { @bound 'onDropboxClose' }
    />


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


  render: ->

    <div className={kd.utils.curry "ChatInputWidget", @props.className}>
      { @renderDropbox() }
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

