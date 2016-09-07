kd          = require 'kd'
React       = require 'kd-react'
immutable   = require 'immutable'
Avatar      = require 'app/components/profile/avatar'
DropBoxItem = require 'activity/components/dropboxitem'

module.exports = class ChannelParticipantsDropdownItemView extends React.Component

  @propTypes =
    isSelected : React.PropTypes.bool
    index      : React.PropTypes.number
    item       : React.PropTypes.instanceOf(immutable.Map).isRequired


  @defaultProps =
    index      : 0
    isSelected : no


  render: ->

    { item } = @props
    <DropBoxItem {...@props} className="ChannelParticipantsDropdownItem">
      <Avatar
        width={30}
        height={30}
        account={item.toJS()}
        className='ChannelParticipantAvatars-avatar' />
      <span className='ChannelParticipantsDropdownItem-nickname'>
        {item.getIn ['profile', 'nickname']}
      </span>
    </DropBoxItem>
