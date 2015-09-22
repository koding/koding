kd                   = require 'kd'
React                = require 'kd-react'
TextArea             = require 'react-autosize-textarea'
EmojiDropbox         = require 'activity/components/emojidropbox'
ChannelDropbox       = require 'activity/components/channeldropbox'
UserDropbox          = require 'activity/components/userdropbox'
EmojiSelector        = require 'activity/components/emojiselector'
SearchDropbox        = require 'activity/components/searchdropbox'
ActivityFlux         = require 'activity/flux'
ChatInputFlux        = require 'activity/flux/chatinput'
KDReactorMixin       = require 'app/flux/reactormixin'
formatEmojiName      = require 'activity/util/formatEmojiName'
KeyboardKeys         = require 'app/util/keyboardKeys'
Link                 = require 'app/components/common/link'
whoami               = require 'app/util/whoami'
helpers              = require './helpers'
groupifyLink         = require 'app/util/groupifyLink'
focusOnGlobalKeyDown = require 'activity/util/focusOnGlobalKeyDown'


module.exports = class ChatInputWidget extends React.Component

  { TAB, ESC, ENTER, SPACE, UP_ARROW, RIGHT_ARROW, DOWN_ARROW, LEFT_ARROW } = KeyboardKeys

  @defaultProps =
    enableSearch : no

  constructor: (props) ->

    super props

    @state = { value : '' }


  getDataBindings: ->

    { getters } = ChatInputFlux

    return {
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
    }


  getDropboxes: -> [ @refs.emojiDropbox, @refs.channelDropbox, @refs.userDropbox, @refs.searchDropbox ]


  onChange: (event) ->

    { value } = event.target
    @setState { value }

    textInput = React.findDOMNode @refs.textInput
    textData  =
      currentWord : helpers.getCurrentWord textInput
      value       : value

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
      @props.onSubmit? { value }
      @setState { value: '' }


  onEsc: (event) ->

    dropbox.close()  for dropbox in @getDropboxes() when dropbox?


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


  onDropboxItemConfirmed: (item) ->

    textInput = React.findDOMNode @refs.textInput

    { value, cursorPosition } = helpers.insertDropboxItem textInput, item
    @setState { value }

    kd.utils.defer ->
      helpers.setCursorPosition textInput, cursorPosition


  onSelectorItemConfirmed: (item) ->

    { value } = @state

    newValue = value + item
    @setState { value : newValue }

    textInput = React.findDOMNode this.refs.textInput
    textInput.focus()


  onSearchItemConfirmed: (message) ->

    { initialChannelId, slug } = message
    ActivityFlux.actions.channel.loadChannelById(initialChannelId).then ({ channel }) ->
      kd.singletons.router.handleRoute groupifyLink "/Channels/#{channel.name}/#{slug}"


  handleEmojiButtonClick: (event) ->

    ChatInputFlux.actions.emoji.setCommonListVisibility @stateId, yes


  handleSearchButtonClick: (event) ->

    searchMarker = '/s '
    { value }    = @state

    if value.indexOf(searchMarker) is -1
      value = searchMarker + value
      @setState { value }

    textInput = React.findDOMNode @refs.textInput
    textInput.focus()

    @refs.searchDropbox.checkTextForQuery { value }


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

    { enableSearch } = @props
    return  unless enableSearch

    { searchItems, searchSelectedIndex, searchSelectedItem, searchQuery, searchVisibility } = @state

    <SearchDropbox
      items           = { searchItems }
      selectedIndex   = { searchSelectedIndex }
      selectedItem    = { searchSelectedItem }
      query           = { searchQuery }
      visible         = { searchVisibility }
      onItemConfirmed = { @bound 'onSearchItemConfirmed' }
      ref             = 'searchDropbox'
      stateId         = { @stateId }
    />


  renderSearchButton: ->

    { enableSearch } = @props
    return  unless enableSearch

    <Link
      className = "ChatInputWidget-searchButton"
      onClick   = { @bound 'handleSearchButtonClick' }
    />


  render: ->

    <div className="ChatInputWidget">
      { @renderEmojiSelector() }
      { @renderEmojiDropbox() }
      { @renderChannelDropbox() }
      { @renderUserDropbox() }
      { @renderSearchDropbox() }
      <TextArea
        value     = { @state.value }
        onChange  = { @bound 'onChange' }
        onKeyDown = { @bound 'onKeyDown' }
        ref       = 'textInput'
      />
      { @renderSearchButton() }
      <Link
        className = "ChatInputWidget-emojiButton"
        onClick   = { @bound 'handleEmojiButtonClick' }
      />
    </div>


React.Component.include.call ChatInputWidget, [KDReactorMixin]

