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
      filteredEmojiListSelectedItem  : getters.filteredEmojiListSelectedItem
      filteredEmojiListQuery         : getters.filteredEmojiListQuery
      commonEmojiList                : getters.commonEmojiList
      commonEmojiListSelectedItem    : getters.commonEmojiListSelectedItem
      commonEmojiListVisibility      : getters.commonEmojiListVisibility
      channels                       : getters.chatInputChannels
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

    textInput   = React.findDOMNode @refs.textInput
    dropupQuery = helpers.getDropupQuery textInput

    for dropup in @getDropups()
      dropup.setQuery dropupQuery


  onKeyDown: (event) ->

    switch event.which
      when ENTER
        @onEnter event
      when ESC
        @onEsc event
      when RIGHT_ARROW, DOWN_ARROW, TAB
        @onNextPosition event
      when LEFT_ARROW, UP_ARROW
        @onPrevPosition event


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


  onNextPosition: (event) ->

    for dropup in @getDropups()
      continue  unless dropup.isActive()

      stopEvent = dropup.moveToNextPosition()
      kd.utils.stopDOMEvent event  if stopEvent
      break


  onPrevPosition: (event) ->

    for dropup in @getDropups()
      continue  unless dropup.isActive()

      stopEvent = dropup.moveToPrevPosition()
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


  handleEmojiButtonClick: (event) ->

    ActivityFlux.actions.emoji.setCommonListVisibility yes


  renderEmojiDropup: ->

    { filteredEmojiList, filteredEmojiListSelectedItem, filteredEmojiListQuery } = @state

    <EmojiDropup
      items           = { filteredEmojiList }
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

    { channels, channelsSelectedItem, channelsQuery, channelsVisibility } = @state

    <ChannelDropup
      items           = { channels }
      selectedItem    = { channelsSelectedItem }
      query           = { channelsQuery }
      visible         = { channelsVisibility }
      onItemConfirmed = { @bound 'onDropupItemConfirmed' }
      ref             = 'channelDropup'
    />


  renderUserDropup: ->

    { users, usersSelectedItem, usersQuery, usersVisibility } = @state

    <UserDropup
      items           = { users }
      selectedItem    = { usersSelectedItem }
      query           = { usersQuery }
      visible         = { usersVisibility }
      onItemConfirmed = { @bound 'onDropupItemConfirmed' }
      ref             = 'userDropup'
    />


  renderSearchDropup: ->

    { searchItems, searchSelectedItem, searchQuery, searchVisibility } = @state

    <SearchDropup
      items           = { searchItems }
      selectedItem    = { searchSelectedItem }
      query           = { searchQuery }
      visible         = { searchVisibility }
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
    </div>


React.Component.include.call ChatInputWidget, [KDReactorMixin]