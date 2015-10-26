kd                          = require 'kd'
whoami                      = require 'app/util/whoami'
React                       = require 'kd-react'
Avatar                      = require 'app/components/profile/avatar'
KDReactorMixin              = require 'app/flux/base/reactormixin'
immutable                   = require 'immutable'
classnames                  = require 'classnames'
AppFlux                     = require 'app/flux'
ActivityFlux                = require 'activity/flux'
ProfileLinkContainer        = require 'app/components/profile/profilelinkcontainer'
ChannelParticipantsDropdown = require 'activity/components/channelparticipantsdropdown'
DropboxInputMixin           = require 'activity/components/dropbox/dropboxinputmixin'
getGroup                    = require 'app/util/getGroup'
isUserGroupAdmin            = require 'app/util/isusergroupadmin'
validator                   = require 'validator'
showErrorNotification       = require 'app/util/showErrorNotification'


module.exports = class ChannelParticipantAvatars extends React.Component

  @include [DropboxInputMixin]

  PREVIEW_COUNT     = 0
  MAX_PREVIEW_COUNT = 19

  @defaultProps =
    channelThread : null
    participants  : null

  constructor: (props) ->

    super

    @state =
      value                 : ''
      isGroupAdmin          : no
      showAllParticipants   : no
      addNewParticipantMode : no


  getDataBindings: ->

    { getters } = ActivityFlux

    return {
      query              : getters.channelParticipantsSearchQuery
      dropdownUsers      : getters.channelParticipantsInputUsers
      selectedItem       : getters.channelParticipantsSelectedItem
      selectedIndex      : getters.channelParticipantsSelectedIndex
      dropdownVisibility : getters.channelParticipantsDropdownVisibility
    }


  componentDidMount: ->

    isUserGroupAdmin (err, isAdmin) =>

      return showErrorNotification err  if err

      @setState isGroupAdmin: isAdmin

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

    participants = participants.slice 0, @getPreviewCount()

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
        +{moreCount}
      </div>
    </div>


  renderAllParticipantsMenu: ->

    return null  unless @state.showAllParticipants
    return null  unless @props.participants

    { participants }  = @props
    otherParticipants = participants.slice @getPreviewCount()

    <div className='ChannelParticipantAvatars-allParticipantsMenu' ref='AllParticipantsMenu'>
      <div className='ChannelParticipantAvatars-allParticipantsMenuTitle'>Other participants</div>
      <div className='ChannelParticipantAvatars-allParticipantsMenuContainer'>
        {@renderAvatars(otherParticipants, yes)}
      </div>
    </div>


  getAddNewParticipantButtonClassNames: ->

    isParticipant = @props.channelThread.getIn ['channel', 'isParticipant']

    return classnames
      'ChannelParticipantAvatars-newParticipantBox': yes
      'cross': @state.addNewParticipantMode
      'hidden': not isParticipant


  renderNewParticipantButton: ->

    <div className='ChannelParticipantAvatars-singleBox'>
      <div
        className={@getAddNewParticipantButtonClassNames()}
        onClick={@bound 'onNewParticipantButtonClick'}
       />
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


  isGroupChannel: ->

    channelId = @props.channelThread.getIn ['channel','id']

    return channelId is getGroup().socialApiDefaultChannelId


  onEnter: (event) ->

    DropboxInputMixin.onEnter.call this, event

    if @state.isGroupAdmin and @isGroupChannel()

      value        = event.target.value.trim()
      isValidEmail = validator.isEmail value

      if isValidEmail

        { channel, user } = ActivityFlux.actions

        channel.inviteMember([{email: value}]).then ->
          user.unsetChannelParticipantsInputQuery()


  getPlaceHolder: ->

    placeholder  = 'type a @username and hit enter'

    if @state.isGroupAdmin and @isGroupChannel()
      placeholder = 'type a @username or email'

    return placeholder


  renderAddNewParticipantInput: ->

    <div className={@getNewParticipantInputClassNames()}>
      <input ref='ChannelParticipantsInput'
        onKeyDown   = { @bound 'onKeyDown' }
        onChange    = { @bound 'onChange' }
        placeholder = { @getPlaceHolder() }
        value       = { @state.value }
        ref         = 'textInput'
      />
    </div>


  onDropdownItemConfirmed: (item) ->

    channelId   = @props.channelThread.get 'channelId'
    participant = @state.selectedItem

    userIds     = [ participant.get '_id' ]
    accountIds  = [ participant.get 'socialApiId' ]

    { channel } = ActivityFlux.actions

    channel.addParticipants channelId, accountIds, userIds

    @setState value: ''


  renderAddNewChannelParticipantsDropdown: ->

    <ChannelParticipantsDropdown
      ref             = 'dropdown'
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
