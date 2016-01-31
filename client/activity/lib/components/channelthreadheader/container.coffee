kd             = require 'kd'
View           = require './view'
React          = require 'kd-react'
immutable      = require 'immutable'
ActivityFlux   = require 'activity/flux'
isGroupChannel = require 'app/util/isgroupchannel'
KeyboardKeys   = require 'app/constants/keyboardKeys'

module.exports = class ChannelThreadHeaderContainer extends React.Component

  @propTypes =
    className                  : React.PropTypes.string
    onInvitePeople             : React.PropTypes.func.isRequired
    onLeaveChannel             : React.PropTypes.func.isRequired
    onShowNotificationSettings : React.PropTypes.func.isRequired
    thread                     : React.PropTypes.instanceOf immutable.Map


  @defaultProps =
    className                  : ''
    thread                     : immutable.Map()


  constructor: (props) ->

    super props

    @state =
      editingPurpose : no
      thread         : @props.thread


  channel: (keyPath...) -> @state.thread.getIn ['channel'].concat keyPath


  componentWillReceiveProps: (nextProps) ->

    return  unless @props.thread and nextProps.thread

    nextState = { thread: nextProps.thread }

    id = @props.thread.get 'channelId'
    nextId = nextProps.thread.get 'channelId'

    # make sure that editing purpose is set back to no if channel is changing.
    nextState['editingPurpose'] = no  if id isnt nextId

    @setState nextState


  getMenuItems: ->

    channel = @state.thread.get('channel').toJS()
    result  = [
      title   : 'Invite people'
      key     : 'invitepeople'
      onClick : @props.onInvitePeople
    ,
      title   : 'Update purpose'
      key     : 'updatepurpose'
      onClick : @bound 'onUpdatePurpose'
    ]

    # notification settings should be visible only public channels
    if channel.typeConstant isnt 'privatemessage'
      notificationSettings =
        title   : 'Notification settings'
        key     : 'notificationsettings'
        onClick : @props.onShowNotificationSettings

      result.push notificationSettings

    # if channel isn't a team channel,
    # add "Leave channel" at the 2nd position of the list
    unless isGroupChannel channel

      isPrivate = channel.typeConstant is 'privatemessage'
      title = if isPrivate
      then 'Leave conversation'
      else 'Leave channel'

      result.splice 1, 0, {
        title   : title
        key     : 'leavechannel'
        onClick : @props.onLeaveChannel
      }

    return result


  onUpdatePurpose: ->

    @setState { editingPurpose: yes }, =>
      kd.utils.moveCaretToEnd @refs.view.refs.purposeInput


  onVideoStart: -> @setState { isModalOpen: yes }


  onClose: -> @setState { isModalOpen: no }


  handlePurposeInputChange: (newValue) ->

    thread = @state.thread

    unless @channel '_originalPurpose'
      thread = thread.setIn ['channel', '_originalPurpose'], @channel 'purpose'

    thread = thread.setIn ['channel', 'purpose'], newValue
    @setState { thread }


  onKeyDown: (event) ->

    { ENTER, ESC } = KeyboardKeys
    { thread }     = @state

    if event.which is ESC
      _originalPurpose = @channel '_originalPurpose'
      purpose = _originalPurpose or @channel 'purpose'
      thread  = thread.setIn ['channel', 'purpose'], purpose
      @setState { thread, editingPurpose: no }

    if event.which is ENTER
      id = @channel 'id'
      purpose = @channel('purpose').trim()
      { updateChannel } = ActivityFlux.actions.channel

      updateChannel({ id, purpose }).then => @setState { editingPurpose: no }


  render: ->

    return null  unless @state.thread

    <View
      ref            = 'view'
      thread         = { @state.thread }
      menuItems      = { @getMenuItems() }
      className      = { @props.className }
      onClose        = { @bound 'onClose' }
      onKeyDown      = { @bound 'onKeyDown' }
      onVideoStart   = { @bound 'onVideoStart' }
      editingPurpose = { @state.editingPurpose }
      onChange       = { @bound 'handlePurposeInputChange' } />
