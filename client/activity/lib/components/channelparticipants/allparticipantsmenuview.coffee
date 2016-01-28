React       = require 'kd-react'
immutable   = require 'immutable'
AvatarsView = require './avatarsview'

module.exports = class ChannelAllParticipantsMenuView extends React.Component

  @propTypes =
    participants : React.PropTypes.instanceOf immutable.Map


  @defaultProps =
    participants : immutable.Map()


  render: ->

    <div className='ChannelParticipantAvatars-allParticipantsMenu' ref='AllParticipantsMenu'>
      <div className='ChannelParticipantAvatars-allParticipantsMenuTitle'>Other participants</div>
        <AvatarsView
          participants        = @props.participants
          isNicknameVisible   = { yes }
          shouldTooltipRender = { no }
          className           = 'ChannelParticipantAvatars-allParticipantsList' />
    </div>

