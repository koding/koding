kd         = require 'kd'
React      = require 'kd-react'
immutable  = require 'immutable'
DropBoxItem = require 'activity/components/dropboxitem'
Avatar     = require 'app/components/profile/avatar'

module.exports = class ChannelParticipantsDropdownItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0


  render: ->

    { item } = @props
    <DropBoxItem {...@props} className="ChannelParticipantsDropdownItem">
      <Avatar
        className='ChannelParticipantAvatars-avatar'
        width={30}
        account={item.toJS()}
        height={30} />
      <span>{item.getIn ['profile', 'nickname']}</span>
    </DropBoxItem>

