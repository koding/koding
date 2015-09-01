kd              = require 'kd'
React           = require 'kd-react'
TextArea        = require 'react-autosize-textarea'
EmojiDropup     = require 'activity/components/emojidropup'
ChannelDropup   = require 'activity/components/channeldropup'
UserDropup      = require 'activity/components/userdropup'
EmojiSelector   = require 'activity/components/emojiselector'
SearchDropup    = require 'activity/components/searchdropup'
ActivityFlux    = require 'activity/flux'
KDReactorMixin  = require 'app/flux/reactormixin'
formatEmojiName = require 'activity/util/formatEmojiName'
Link            = require 'app/components/common/link'
helpers         = require './helpers'
groupifyLink   = require 'app/util/groupifyLink'


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
      filteredEmojiList              : getters.filteredEmojiList
      filteredEmojiListSelectedIndex : getters.filteredEmojiListSelectedIndex
      filteredEmojiListSelectedItem  : getters.filteredEmojiListSelectedItem
      filteredEmojiListQuery         : getters.filteredEmojiListQuery
      commonEmojiList                : getters.commonEmojiList
      commonEmojiListSelectedItem    : getters.commonEmojiListSelectedItem
      commonEmojiListVisibility      : getters.commonEmojiListVisibility
      channels                       : getters.chatInputChannels
      channelsSelectedIndex          : getters.chatInputChannelsSelectedIndex
      channelsSelectedItem           : getters.chatInputChannelsSelectedItem
      channelsQuery                  : getters.chatInputChannelsQuery
      channelsVisibility             : getters.chatInputChannelsVisibility
      users                          : getters.chatInputUsers
      usersQuery                     : getters.chatInputUsersQuery
      userSelectedIndex              : getters.chatInputUsersSelectedIndex
      usersSelectedItem              : getters.chatInputUsersSelectedItem
      usersVisibility                : getters.chatInputUsersVisibility
      searchItems                    : getters.chatInputSearchItems
      searchQuery                    : getters.chatInputSearchQuery
      searchSelectedIndex            : getters.chatInputSearchSelectedIndex
      searchSelectedItem             : getters.chatInputSearchSelectedItem
      searchVisibility               : getters.chatInputSearchVisibility
    }


  getDropups: -> [ @refs.emojiDropup, @refs.channelDropup, @refs.userDropup, @refs.searchDropup ]


  onChange: (event) ->

    { value } = event.target
    @setState { value }

    textInput = React.findDOMNode @refs.textInput
    textData  =
      currentWord : helpers.getCurrentWord textInput
      value       : value

    # Let every dropup check entered text.
    # If any dropup considers text as a query,
    # stop checking for others and close active dropup
    # if it exists
    queryIsSet = no
    for dropup in @getDropups()
      unless queryIsSet
        queryIsSet = dropup.checkTextForQuery textData
        continue  if queryIsSet

      dropup.close()  if dropup.isActive()


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

    isDropupEnter = no
    for dropup in @getDropups()
      continue  unless dropup.isActive()

      dropup.confirmSelectedItem()
      isDropupEnter = yes
      break

    unless isDropupEnter
      @props.onSubmit? { value: @state.value }
      @setState { value: '' }


  onEsc: (event) ->

    dropup.close() for dropup in @getDropups()


  onNextPosition: (event, keyInfo) ->

    for dropup in @getDropups()
      continue  unless dropup.isActive()

      stopEvent = dropup.moveToNextPosition keyInfo
      kd.utils.stopDOMEvent event  if stopEvent
      break


  onPrevPosition: (event, keyInfo) ->

    for dropup in @getDropups()
      continue  unless dropup.isActive()

      stopEvent = dropup.moveToPrevPosition keyInfo
      kd.utils.stopDOMEvent event  if stopEvent
      break


  onDropupItemConfirmed: (item) ->

    textInput = React.findDOMNode @refs.textInput

    { value, cursorPosition } = helpers.insertDropupItem textInput, item
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

    ActivityFlux.actions.emoji.setCommonListVisibility yes


  handleSearchButtonClick: (event) ->


  renderEmojiDropup: ->

    { filteredEmojiList, filteredEmojiListSelectedIndex, filteredEmojiListSelectedItem, filteredEmojiListQuery } = @state

    <EmojiDropup
      items           = { filteredEmojiList }
      selectedIndex   = { filteredEmojiListSelectedIndex }
      selectedItem    = { filteredEmojiListSelectedItem }
      query           = { filteredEmojiListQuery }
      onItemConfirmed = { @bound 'onDropupItemConfirmed' }
      ref             = 'emojiDropup'
    />


  renderEmojiSelector: ->

    { commonEmojiList, commonEmojiListVisibility, commonEmojiListSelectedItem } = @state

    <EmojiSelector
      items           = { commonEmojiList }
      visible         = { commonEmojiListVisibility }
      selectedItem    = { commonEmojiListSelectedItem }
      onItemConfirmed = { @bound 'onSelectorItemConfirmed' }
    />


  renderChannelDropup: ->

    { channels, channelsSelectedItem, channelsSelectedIndex, channelsQuery, channelsVisibility } = @state

    <ChannelDropup
      items           = { channels }
      selectedIndex   = { channelsSelectedIndex }
      selectedItem    = { channelsSelectedItem }
      query           = { channelsQuery }
      visible         = { channelsVisibility }
      onItemConfirmed = { @bound 'onDropupItemConfirmed' }
      ref             = 'channelDropup'
    />


  renderUserDropup: ->

    { users, userSelectedIndex, usersSelectedItem, usersQuery, usersVisibility } = @state

    <UserDropup
      items           = { users }
      selectedIndex   = { userSelectedIndex }
      selectedItem    = { usersSelectedItem }
      query           = { usersQuery }
      visible         = { usersVisibility }
      onItemConfirmed = { @bound 'onDropupItemConfirmed' }
      ref             = 'userDropup'
    />


  renderSearchDropup: ->

    { searchItems, searchSelectedIndex, searchSelectedItem, searchQuery, searchVisibility } = @state

    <SearchDropup
      items           = { searchItems }
      selectedIndex   = { searchSelectedIndex }
      selectedItem    = { searchSelectedItem }
      query           = { searchQuery }
      visible         = { searchVisibility }
      onItemConfirmed = { @bound 'onSearchItemConfirmed' }
      ref             = 'searchDropup'
    />


  render: ->

    <div className="ChatInputWidget">
      { @renderEmojiSelector() }
      { @renderEmojiDropup() }
      { @renderChannelDropup() }
      { @renderUserDropup() }
      { @renderSearchDropup() }
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
      <Link
        className = "ChatInputWidget-searchButton"
        onClick   = { @bound 'handleSearchButtonClick' }
      />
    </div>


React.Component.include.call ChatInputWidget, [KDReactorMixin]

