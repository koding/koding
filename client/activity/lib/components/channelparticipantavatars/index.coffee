kd                          = require 'kd'
whoami                      = require 'app/util/whoami'
React                       = require 'kd-react'
Avatar                      = require 'app/components/profile/avatar'
KDReactorMixin              = require 'app/flux/reactormixin'
immutable                   = require 'immutable'
classnames                  = require 'classnames'
AppFlux                     = require 'app/flux'
ActivityFlux                = require 'activity/flux'
KeyboardKeys                = require 'app/util/keyboardKeys'
ProfileLinkContainer        = require 'app/components/profile/profilelinkcontainer'
ChannelParticipantsDropdown = require 'activity/components/channelparticipantsdropdown'

module.exports = class ChannelParticipantAvatars extends React.Component

  { TAB, ESC, ENTER, UP_ARROW, DOWN_ARROW } = KeyboardKeys

  PREVIEW_COUNT     = 0
  MAX_PREVIEW_COUNT = 4

  @defaultProps =
    channelThread : null
    participants  : null

  constructor: (props) ->

    super

    @state = { addNewParticipantMode: no, showAllParticipants: no, value: '' }


  getDataBindings: ->

    { getters } = ActivityFlux

    return {
      query              : getters.channelParticipantsSearchQuery
      dropdownUsers      : getters.channelParticipantsInputUsers
      selectedItem       : getters.channelParticipantsSelectedItem
      selectedIndex      : getters.channelParticipantsSelectedIndex
      dropdownVisibility : getters.channelParticipantsDropdownVisibility
    }


  getParticipantsDropdown: -> @refs.channelParticipantsDropdown


  componentDidMount: ->

    document.addEventListener 'mousedown', @bound 'handleOutsideMouseClick'


  componentWillUnmount: ->

    document.removeEventListener 'mousedown', @bound 'handleOutsideMouseClick'


  handleOutsideMouseClick: (event) ->

    return  unless @refs.AllParticipantsMenu

    target             = event.target
    moreButtonEl       = @refs.showMoreButton.getDOMNode()
    participantsMenuEl = @refs.AllParticipantsMenu.getDOMNode()

    if ((@isNodeInContainer target, moreButtonEl) or (@isNodeInContainer target, participantsMenuEl))
      return

    event.stopPropagation()
    @setState showAllParticipants: no


  isNodeInContainer: (el, container) ->
    while el
      return yes  if el is container
      el = el.parentNode
    no


  getPreviewCount: ->

    { participants } = @props

    diff = participants.size is MAX_PREVIEW_COUNT

    PREVIEW_COUNT = switch
      when diff is 0 then MAX_PREVIEW_COUNT
      when diff < 0 then participants.size
      else MAX_PREVIEW_COUNT - 1


  onNewParticipantButtonClick: ->

    if @state.addNewParticipantMode is yes
    then @setState addNewParticipantMode: no
    else @setState addNewParticipantMode: yes


  onShowMoreParticipantButtonClick: (event) ->

    event.stopPropagation()
    if @state.showAllParticipants is yes
    then @setState showAllParticipants: no
    else @setState showAllParticipants: yes


  renderPreviewAvatars: ->

    return null  unless @props.participants

    { participants } = @props

    PREVIEW_COUNT = @getPreviewCount()

    participants = participants.slice 0, PREVIEW_COUNT

    @renderAvatars participants, no


  renderNickname: (participant, isNicknameVisible)->

    return  if isNicknameVisible is no

    nickname = participant.getIn ['profile', 'nickname']
    <span>{nickname}</span>


  renderAvatars: (participants, isNicknameVisible) ->

    participants.toList().map (participant) =>
      <div key={participant.get 'id'} className='ChannelParticipantAvatars-singleBox'>
        <ProfileLinkContainer account={participant.toJS()}>
          <div>
            <Avatar
              className='ChannelParticipantAvatars-avatar'
              width={30}
              account={participant.toJS()}
              height={30} />
            {@renderNickname participant, isNicknameVisible }
          </div>
        </ProfileLinkContainer>
      </div>


  renderMoreCount: ->

    return null  unless @props.participants

    moreCount = @props.participants.size - PREVIEW_COUNT

    return null  unless moreCount > 0

    moreCount = Math.min moreCount, 99

    <div className='ChannelParticipantAvatars-singleBox'>
      <div className='ChannelParticipantAvatars-moreCount' ref='showMoreButton' onClick={@bound 'onShowMoreParticipantButtonClick'}>
        {moreCount}+
      </div>
    </div>


  renderAllParticipantsMenu: ->

    return null  unless @state.showAllParticipants
    return null  unless @props.participants

    { participants } = @props

    <div className='ChannelParticipantAvatars-allParticipantsMenu' ref='AllParticipantsMenu'>
      <div className='ChannelParticipantAvatars-allParticipantsMenuContainer'>
        <div className='ChannelParticipantAvatars-allParticipantsMenuTitle'>Other participants</div>
        {@renderAvatars(participants, yes)}
      </div>
    </div>


  getAddNewParticipantButtonClassNames: -> classnames
    'ChannelParticipantAvatars-newParticipantBox': yes
    'cross': @state.addNewParticipantMode


  renderNewParticipantButton: ->

    <div className='ChannelParticipantAvatars-singleBox' onClick={@bound 'onNewParticipantButtonClick'}>
      <div className={@getAddNewParticipantButtonClassNames()}></div>
    </div>


  getNewParticipantInputClassNames: -> classnames
    'ChannelParticipantInput': yes
    'slide-down': @state.addNewParticipantMode


  onChange: (event) ->

    { value } = event.target
    @setState { value }

    matchResult = value.match /^@(.*)/

    query = value
    query = matchResult[1]  if matchResult

    { channel, user } = ActivityFlux.actions

    user.setChannelParticipantsInputQuery query
    channel.setChannelParticipantsDropdownVisibility yes


  onEnter: (event) ->

    return  if event.shiftKey

    kd.utils.stopDOMEvent event

    dropdown = @getParticipantsDropdown()

    if dropdown.isActive()

      dropdown.confirmSelectedItem()


  onEsc: (event) ->

    @getParticipantsDropdown().close()


  onNextPosition: (event, keyInfo) ->

    dropdown = @getParticipantsDropdown()

    if dropdown.isActive()

      stopEvent = dropdown.moveToNextPosition keyInfo
      kd.utils.stopDOMEvent event  if stopEvent


  onPrevPosition: (event, keyInfo) ->

    dropdown = @getParticipantsDropdown()

    if dropdown.isActive()

      stopEvent = dropdown.moveToPrevPosition keyInfo
      kd.utils.stopDOMEvent event  if stopEvent


  onKeyDown: (event) ->

    switch event.which
      when ENTER       then @onEnter event
      when ESC         then @onEsc event
      when TAB         then @onNextPosition event, { isTab : yes }
      when DOWN_ARROW  then @onNextPosition event, { isDownArrow : yes }
      when UP_ARROW    then @onPrevPosition event, { isUpArrow : yes }


  renderAddNewParticipantInput: ->

    <div className={@getNewParticipantInputClassNames()}>
      <input ref='ChannelParticipantsInput'
        onKeyDown   = { @bound 'onKeyDown' }
        onChange    = { @bound 'onChange' }
        placeholder = 'type a @username and hit enter'
        value       = { @state.value }
        ref         = 'textInput'
      />
    </div>


  onDropdownItemConfirmed: (item) ->

    channelId   = @props.channelThread.get 'channelId'
    participant = @state.selectedItem

    options =
      userId            : participant.get '_id'
      channelId         : @props.channelThread.get 'channelId'
      accountIds        : [ participant.get 'socialApiId' ]

    { channel } = ActivityFlux.actions
    channel.addParticipants options


  renderAddNewChannelParticipantsDropdown: ->

    <ChannelParticipantsDropdown
      ref             = 'channelParticipantsDropdown'
      query           = { @state.query }
      value           = { @state.value }
      visible         = { @state.dropdownVisibility }
      items           = { @state.dropdownUsers }
      selectedItem    = { @state.selectedItem }
      selectedIndex   = { @state.selectedIndex }
      onItemConfirmed = { @bound 'onDropdownItemConfirmed' }
    />


  render: ->
    <div>
      <div className='ChannelParticipantAvatars'>
        {@renderPreviewAvatars()}
        {@renderMoreCount()}
        {@renderNewParticipantButton()}
      </div>
        {@renderAddNewParticipantInput()}
        {@renderAllParticipantsMenu()}
        {@renderAddNewChannelParticipantsDropdown()}
    </div>


React.Component.include.call ChannelParticipantAvatars, [KDReactorMixin]
