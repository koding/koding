kd                   = require 'kd'
React                = require 'kd-react'
TextArea             = require 'react-autosize-textarea'
EmojiDropbox         = require 'activity/components/emojidropbox'
ChannelDropbox       = require 'activity/components/channeldropbox'
UserDropbox          = require 'activity/components/userdropbox'
EmojiSelector        = require 'activity/components/emojiselector'
SearchDropbox        = require 'activity/components/searchdropbox'
CommandDropbox       = require 'activity/components/commanddropbox'
ActivityFlux         = require 'activity/flux'
ChatInputFlux        = require 'activity/flux/chatinput'
KDReactorMixin       = require 'app/flux/reactormixin'
formatEmojiName      = require 'activity/util/formatEmojiName'
KeyboardKeys         = require 'app/util/keyboardKeys'
Link                 = require 'app/components/common/link'
whoami               = require 'app/util/whoami'
helpers              = require './helpers'
focusOnGlobalKeyDown = require 'activity/util/focusOnGlobalKeyDown'
parseStringToCommand = require 'activity/util/parseStringToCommand'


module.exports = class ChatInputWidget extends React.Component

  { TAB, ESC, ENTER, UP_ARROW, RIGHT_ARROW, DOWN_ARROW, LEFT_ARROW } = KeyboardKeys

  @defaultProps =
    disabledFeatures : []


  getDataBindings: ->

    { getters }          = ChatInputFlux
    { disabledFeatures } = @props

    return {
      value                          : getters.currentValue @stateId
      filteredEmojiList              : getters.filteredEmojiList @stateId
      filteredEmojiListSelectedIndex : getters.filteredEmojiListSelectedIndex @stateId
      filteredEmojiListSelectedItem  : getters.filteredEmojiListSelectedItem @stateId
      filteredEmojiListQuery         : getters.filteredEmojiListQuery @stateId
      commonEmojiList                : getters.commonEmojiList
      commonEmojiListSelectedItem    : getters.commonEmojiListSelectedItem @stateId
      commonEmojiListVisibility      : getters.commonEmojiListVisibility @stateId
      channels                       : getters.channels @stateId
      channelsSelectedIndex          : getters.channelsSelectedIndex @stateId
      channelsSelectedItem           : getters.channelsSelectedItem @stateId
      channelsQuery                  : getters.channelsQuery @stateId
      channelsVisibility             : getters.channelsVisibility @stateId
      users                          : getters.users @stateId
      usersQuery                     : getters.usersQuery @stateId
      userSelectedIndex              : getters.usersSelectedIndex @stateId
      usersSelectedItem              : getters.usersSelectedItem @stateId
      usersVisibility                : getters.usersVisibility @stateId
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

    focusOnGlobalKeyDown React.findDOMNode this.refs.textInput
    @setValue value  if value


  componentDidUpdate: (oldProps, oldState) ->

    @focus()  if oldState.value isnt @state.value


  isFeatureDisabled: (feature) -> @props.disabledFeatures.indexOf(feature) > -1


  getDropboxes: -> [ @refs.emojiDropbox, @refs.channelDropbox, @refs.userDropbox, @refs.searchDropbox, @refs.commandDropbox ]


  setValue: (value) ->

    { channelId } = @props
    ChatInputFlux.actions.value.setValue channelId, @stateId, value


  resetValue: ->

    { channelId } = @props
    ChatInputFlux.actions.value.resetValue channelId, @stateId


  getValue: -> @state.value


  onChange: (event) ->

    { value } = event.target

    @setValue value
    @runDropboxChecks value


  runDropboxChecks: (value) ->

    textInput = React.findDOMNode @refs.textInput
    textData  =
      currentWord : helpers.getCurrentWord textInput
      value       : value
      position    : helpers.getCursorPosition textInput

    # Let every dropbox check entered text.
    # If any dropbox considers text as a query,
    # stop checking for others and close active dropbox
    # if it exists
    queryIsSet = no
    for dropbox in @getDropboxes() when dropbox?
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
    for dropbox in @getDropboxes() when dropbox?
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


  onEsc: (event) ->

    dropbox.close()  for dropbox in @getDropboxes() when dropbox?
    @props.onEsc?()


  onNextPosition: (event, keyInfo) ->

    for dropbox in @getDropboxes() when dropbox?
      continue  unless dropbox.isActive()

      stopEvent = dropbox.moveToNextPosition keyInfo
      kd.utils.stopDOMEvent event  if stopEvent
      break


  onPrevPosition: (event, keyInfo) ->

    if event.target.value
      for dropbox in @getDropboxes() when dropbox?
        continue  unless dropbox.isActive()

        stopEvent = dropbox.moveToPrevPosition keyInfo
        kd.utils.stopDOMEvent event  if stopEvent
        break
    else

      return  unless keyInfo.isUpArrow

      accountId = whoami()._id
      ChatInputFlux.actions.message.setLastMessageEditMode accountId


  onDropboxItemConfirmed: (item, addWhitespace = yes, callback = kd.noop) ->

    textInput = React.findDOMNode @refs.textInput

    item += ' '  if addWhitespace
    { value, cursorPosition } = helpers.insertDropboxItem textInput, item
    @setValue value

    kd.utils.defer ->
      helpers.setCursorPosition textInput, cursorPosition
      callback value


  onSelectorItemConfirmed: (item) ->

    { value } = @state

    newValue = value + item
    @setValue newValue

    @focus()


  onSearchItemConfirmed: (message) ->

    { initialChannelId, id } = message
    ActivityFlux.actions.channel.loadChannelById(initialChannelId).then ({ channel }) ->
      kd.singletons.router.handleRoute "/Channels/#{channel.name}/#{id}"


  onCommandItemConfirmed: (item) ->

    @onDropboxItemConfirmed item, no, (value) =>
      @runDropboxChecks value


  handleEmojiButtonClick: (event) ->

    ChatInputFlux.actions.emoji.setCommonListVisibility @stateId, yes


  focus: ->

    textInput = React.findDOMNode @refs.textInput
    textInput.focus()


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


  renderEmojiSelector: ->

    { commonEmojiList, commonEmojiListVisibility, commonEmojiListSelectedItem } = @state

    <EmojiSelector
      items           = { commonEmojiList }
      visible         = { commonEmojiListVisibility }
      selectedItem    = { commonEmojiListSelectedItem }
      onItemConfirmed = { @bound 'onSelectorItemConfirmed' }
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


  renderUserDropbox: ->

    { users, userSelectedIndex, usersSelectedItem, usersQuery, usersVisibility } = @state

    <UserDropbox
      items           = { users }
      selectedIndex   = { userSelectedIndex }
      selectedItem    = { usersSelectedItem }
      query           = { usersQuery }
      visible         = { usersVisibility }
      onItemConfirmed = { @bound 'onDropboxItemConfirmed' }
      ref             = 'userDropbox'
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
      onItemConfirmed = { @bound 'onCommandItemConfirmed' }
      ref             = 'commandDropbox'
      stateId         = { @stateId }
    />


  render: ->

    <div className="ChatInputWidget">
      { @renderEmojiSelector() }
      { @renderEmojiDropbox() }
      { @renderChannelDropbox() }
      { @renderUserDropbox() }
      { @renderSearchDropbox() }
      { @renderCommandDropbox() }
      <TextArea
        value     = { @state.value }
        onChange  = { @bound 'onChange' }
        onKeyDown = { @bound 'onKeyDown' }
        ref       = 'textInput'
      />
      <Link
        className = "ChatInputWidget-emojiButton"
        onClick   = { @bound 'handleEmojiButtonClick' }
      />
    </div>


React.Component.include.call ChatInputWidget, [KDReactorMixin]

