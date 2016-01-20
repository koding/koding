kd                          = require 'kd'
React                       = require 'kd-react'
immutable                   = require 'immutable'
classnames                  = require 'classnames'
ActivityFlux                = require 'activity/flux'
ChannelParticipantsDropdown = require 'activity/components/channelparticipantsdropdown'
DropdownItem                = require 'activity/components/channelparticipantsdropdownitem'

module.exports = class ChannelParticipantsInputWidgetView extends React.Component

  @propTypes =
    visible               : React.PropTypes.bool
    addNewParticipantMode : React.PropTypes.bool
    placeholder           : React.PropTypes.string
    query                 : React.PropTypes.string
    value                 : React.PropTypes.string
    selectedIndex         : React.PropTypes.number
    onItemConfirmed       : React.PropTypes.func
    onFocus               : React.PropTypes.func
    onChange              : React.PropTypes.func.isRequired
    onKeyDown             : React.PropTypes.func.isRequired
    items                 : React.PropTypes.instanceOf immutable.List


  @defaultProps =
    query                 : ''
    value                 : ''
    placeholder           : ''
    visible               : no
    addNewParticipantMode : no
    selectedItem          : null
    selectedIndex         : null
    onFocus               : kd.noop
    items                 : immutable.List()


  getNewParticipantInputClassNames: -> classnames
    'ChannelParticipantInput' : yes
    'slide-down'              : @props.addNewParticipantMode


  renderDropdown: ->

    { user, channel } = ActivityFlux.actions

    <ChannelParticipantsDropdown.Container
      ref                  = 'dropdown'
      query                = { @props.query }
      value                = { @props.value }
      items                = { @props.items }
      DropdownItem         = { DropdownItem }
      visible              = { @props.visible }
      selectedItem         = { @props.selectedItem }
      selectedIndex        = { @props.selectedIndex }
      onItemConfirmed      = { @props.onItemConfirmed }
      moveToNextAction     = { user.moveToNextChannelParticipantIndex }
      moveToPrevAction     = { user.moveToPrevChannelParticipantIndex }
      onItemSelectedAction = { user.setChannelParticipantsSelectedIndex }
      closeAction          = { channel.setChannelParticipantsDropdownVisibility } />


  render: ->

    <div className={@getNewParticipantInputClassNames()}>
      <input
        ref         = 'textInput'
        value       = { @props.value }
        onChange    = { @props.onChange }
        onKeyDown   = { @props.onKeyDown }
        placeholder = { @props.placeholder } />
        {@renderDropdown()}
    </div>

