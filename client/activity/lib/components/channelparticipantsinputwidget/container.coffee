kd                = require 'kd'
View              = require './view'
React             = require 'kd-react'
ReactDOM          = require 'react-dom'
immutable         = require 'immutable'
ActivityFlux      = require 'activity/flux'
getGroup          = require 'app/util/getGroup'
isUserGroupAdmin  = require 'app/util/isusergroupadmin'
DropboxInputMixin = require 'activity/components/dropbox/dropboxinputmixin'

module.exports = class ChannelParticipantsInputWidgetContainer extends React.Component

  @include [DropboxInputMixin]

  @propsTypes =
    visible               : React.PropTypes.bool
    addNewParticipantMode : React.PropTypes.bool
    query                 : React.PropTypes.string
    channelId             : React.PropTypes.string
    selectedItem          : React.PropTypes.instanceOf immutable.Map
    items                 : React.PropTypes.instanceOf immutable.List


  @defaultProps =
    query                 : ''
    channelId             : ''
    visible               : no
    addNewParticipantMode : no
    selectedIndex         : null
    selectedItem          : immutable.Map()
    items                 : immutable.List()


  constructor: (props) ->

    super

    @state =
      value        : ''
      isGroupAdmin : no


  getDropdown: -> @refs.view.refs.dropdown


  componentDidMount: ->

    isUserGroupAdmin (err, isAdmin) =>

      return showErrorNotification err  if err

      @setState { isGroupAdmin: isAdmin }


  isGroupChannel: -> @props.channelId is getGroup().socialApiDefaultChannelId


  focusOnInput: -> ReactDOM.findDOMNode(@refs.view.refs.textInput).focus()


  onEnter: (event) ->

    DropboxInputMixin.onEnter.call this, event

    if @state.isGroupAdmin and @isGroupChannel()

      value        = event.target.value.trim()
      isValidEmail = validator.isEmail value

      if isValidEmail

        { channel, user } = ActivityFlux.actions

        channel.inviteMember([{email: value}]).then ->
          user.unsetChannelParticipantsInputQuery()


  onChange: (event) ->

    { value } = event.target
    @setState { value }

    matchResult = value.match /^@(.*)/

    query = value
    query = matchResult[1]  if matchResult

    { channel, user } = ActivityFlux.actions

    user.setChannelParticipantsInputQuery query
    channel.setChannelParticipantsDropdownVisibility yes


  getPlaceHolder: ->

    placeholder  = 'type a @username and hit enter'

    if @state.isGroupAdmin and @isGroupChannel()
      placeholder = 'type a @username or email'

    return placeholder


  onDropdownItemConfirmed: ->

    channelId   = @props.channelId
    participant = @props.selectedItem

    userIds     = [ participant.get '_id' ]
    accountIds  = [ participant.get 'socialApiId' ]

    { channel } = ActivityFlux.actions

    channel.addParticipants channelId, accountIds, userIds

    @setState { value: '' }


  render: ->

    <View
      ref                   = 'view'
      items                 = { @props.items }
      value                 = { @state.value }
      query                 = { @props.query }
      visible               = { @props.visible }
      onFocus               = { @props.onFocus }
      onChange              = { @bound 'onChange' }
      placeholder           = { @getPlaceHolder() }
      onKeyDown             = { @bound 'onKeyDown' }
      selectedItem          = { @props.selectedItem }
      selectedIndex         = { @props.selectedIndex }
      onItemConfirmed       = { @bound 'onDropdownItemConfirmed' }
      addNewParticipantMode = { @props.addNewParticipantMode } />

