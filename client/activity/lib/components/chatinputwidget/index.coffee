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
      filteredEmojiList              : getters.filteredEmojiList @stateId
      filteredEmojiListSelectedIndex : getters.filteredEmojiListSelectedIndex @stateId
      filteredEmojiListSelectedItem  : getters.filteredEmojiListSelectedItem @stateId
      filteredEmojiListQuery         : getters.filteredEmojiListQuery @stateId
      emojiSelectBoxItems            : getters.emojiSelectBoxItems @stateId
      emojiSelectBoxTabs             : getters.emojiSelectBoxTabs
      emojiSelectBoxQuery            : getters.emojiSelectBoxQuery @stateId
      emojiSelectBoxSelectedItem     : getters.emojiSelectBoxSelectedItem @stateId
      emojiSelectBoxVisibility       : getters.emojiSelectBoxVisibility @stateId
      emojiSelectBoxTabIndex         : getters.emojiSelectBoxTabIndex @stateId
      channels                       : getters.channels @stateId
      channelsSelectedIndex          : getters.channelsSelectedIndex @stateId
      channelsSelectedItem           : getters.channelsSelectedItem @stateId
      channelsQuery                  : getters.channelsQuery @stateId
      channelsVisibility             : getters.channelsVisibility @stateId
      userMentions                   : getters.userMentions @stateId
      channelMentions                : getters.channelMentions @stateId
      mentionsQuery                  : getters.mentionsQuery @stateId
      mentionsSelectedIndex          : getters.mentionsSelectedIndex @stateId
      mentionsSelectedItem           : getters.mentionsSelectedItem @stateId
      mentionsVisibility             : getters.mentionsVisibility @stateId
      searchItems                    : getters.searchItems @stateId
      searchQuery                    : getters.searchQuery @stateId
      searchSelectedIndex            : getters.searchSelectedIndex @stateId
      searchSelectedItem             : getters.searchSelectedItem @stateId
      searchVisibility               : getters.searchVisibility @stateId
      searchFlags                    : getters.searchFlags @stateId
      commands                       : getters.commands @stateId, disabledFeatures
      commandsQuery                  : getters.commandsQuery @stateId
      commandsSelectedIndex          : getters.commandsSelectedIndex @stateId, disabledFeatures
      commandsSelectedItem           : getters.commandsSelectedItem @stateId, disabledFeatures
      commandsVisibility             : getters.commandsVisibility @stateId
    }


  componentDidMount: ->

    { value } = @props
    @setValue value  if value

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
    @focus()  if isValueChanged
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
    for dropbox in @getDropboxes() when dropbox?
      dropbox.updatePosition inputDimensions


  isFeatureDisabled: (feature) -> @props.disabledFeatures.indexOf(feature) > -1


  getInputDropboxes: -> [ @refs.emojiDropbox, @refs.channelDropbox, @refs.mentionDropbox, @refs.searchDropbox, @refs.commandDropbox ]


  getDropboxes: -> @getInputDropboxes().concat @refs.emojiSelectBox


  setValue: (value) ->

    return  if @state.value is value

    { channelId } = @props

    ChatInputFlux.actions.value.setValue channelId, @stateId, value
    @props.onChange value


  resetValue: ->

    { channelId } = @props
    ChatInputFlux.actions.value.resetValue channelId, @stateId


  getValue: -> @state.value


  onChange: (event) ->

    { value } = event.target

    @setValue value
    @runDropboxChecks value
    @props.onResize()


  runDropboxChecks: (value) ->

    textInput = ReactDOM.findDOMNode @refs.textInput
    textData  =
      currentWord : helpers.getCurrentWord textInput
      value       : value
      position    : helpers.getCursorPosition textInput

    # Let every dropbox check entered text.
    # If any dropbox considers text as a query,
    # stop checking for others and close active dropbox
    # if it exists
    queryIsSet = no
    for dropbox in @getInputDropboxes() when dropbox?
      unless queryIsSet
        queryIsSet = dropbox.checkTextForQuery textData
        continue  if queryIsSet

      dropbox.close()  if dropbox.isActive()


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

    isDropboxEnter = no
    for dropbox in @getInputDropboxes() when dropbox?
      continue  unless dropbox.isActive()

      dropbox.confirmSelectedItem()
      isDropboxEnter = yes
      break

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

    for dropbox in @getInputDropboxes() when dropbox?
      continue  unless dropbox.isActive()

      stopEvent = dropbox.moveToNextPosition keyInfo
      kd.utils.stopDOMEvent event  if stopEvent
      break


  onPrevPosition: (event, keyInfo) ->

    if event.target.value
      for dropbox in @getInputDropboxes() when dropbox?
        continue  unless dropbox.isActive()

        stopEvent = dropbox.moveToPrevPosition keyInfo
        kd.utils.stopDOMEvent event  if stopEvent
        break
    else

      return  unless keyInfo.isUpArrow

      kd.utils.stopDOMEvent event
      ChatInputFlux.actions.message.setLastMessageEditMode()


  onDropboxItemConfirmed: (item) ->

    textInput = ReactDOM.findDOMNode @refs.textInput

    item += ' '
    { value, cursorPosition } = helpers.insertDropboxItem textInput, item
    @setValue value

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

    kd.utils.defer =>
      @runDropboxChecks value


  handleEmojiButtonClick: (event) ->

    ChatInputFlux.actions.emoji.setSelectBoxVisibility @stateId, yes


  focus: ->

    textInput = ReactDOM.findDOMNode @refs.textInput
    textInput.focus()


  closeDropboxes: ->

    dropbox.close()  for dropbox in @getDropboxes() when dropbox?


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


  renderEmojiDropbox: ->

    { filteredEmojiList, filteredEmojiListSelectedIndex, filteredEmojiListSelectedItem, filteredEmojiListQuery } = @state

    <EmojiDropbox
      items           = { filteredEmojiList }
      selectedIndex   = { filteredEmojiListSelectedIndex }
      selectedItem    = { filteredEmojiListSelectedItem }
      query           = { filteredEmojiListQuery }
      onItemConfirmed = { @bound 'onDropboxItemConfirmed' }
      ref             = 'emojiDropbox'
      stateId         = { @stateId }
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


  renderChannelDropbox: ->

    { channels, channelsSelectedItem, channelsSelectedIndex, channelsQuery, channelsVisibility } = @state

    <ChannelDropbox
      items           = { channels }
      selectedIndex   = { channelsSelectedIndex }
      selectedItem    = { channelsSelectedItem }
      query           = { channelsQuery }
      visible         = { channelsVisibility }
      onItemConfirmed = { @bound 'onDropboxItemConfirmed' }
      ref             = 'channelDropbox'
      stateId         = { @stateId }
    />


  renderMentionDropbox: ->

    { userMentions, channelMentions, mentionsSelectedIndex, mentionsSelectedItem } = @state
    { mentionsQuery, mentionsVisibility } = @state

    <MentionDropbox
      userMentions    = { userMentions }
      channelMentions = { channelMentions }
      selectedIndex   = { mentionsSelectedIndex }
      selectedItem    = { mentionsSelectedItem }
      query           = { mentionsQuery }
      visible         = { mentionsVisibility }
      onItemConfirmed = { @bound 'onDropboxItemConfirmed' }
      ref             = 'mentionDropbox'
      stateId         = { @stateId }
    />


  renderSearchDropbox: ->

    return  if @isFeatureDisabled('search') or @isFeatureDisabled('commands')

    { searchItems, searchSelectedIndex, searchSelectedItem, searchQuery, searchVisibility, searchFlags } = @state

    <SearchDropbox
      items           = { searchItems }
      selectedIndex   = { searchSelectedIndex }
      selectedItem    = { searchSelectedItem }
      query           = { searchQuery }
      visible         = { searchVisibility }
      onItemConfirmed = { @bound 'onSearchItemConfirmed' }
      ref             = 'searchDropbox'
      stateId         = { @stateId }
      flags           = { searchFlags }
    />


  renderCommandDropbox: ->

    return  if @isFeatureDisabled 'commands'

    { commands, commandsSelectedItem, commandsSelectedIndex, commandsQuery, commandsVisibility } = @state

    <CommandDropbox
      items           = { commands }
      selectedIndex   = { commandsSelectedIndex }
      selectedItem    = { commandsSelectedItem }
      query           = { commandsQuery }
      visible         = { commandsVisibility }
      onItemConfirmed = { @bound 'setCommand' }
      ref             = 'commandDropbox'
      stateId         = { @stateId }
    />


  render: ->

    <div className={kd.utils.curry "ChatInputWidget", @props.className}>
      { @renderEmojiDropbox() }
      { @renderEmojiSelectBox() }
      { @renderChannelDropbox() }
      { @renderMentionDropbox() }
      { @renderSearchDropbox() }
      { @renderCommandDropbox() }
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

