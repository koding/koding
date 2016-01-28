kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
immutable            = require 'immutable'
Tooltip              = require 'app/components/tooltip'
Avatar               = require 'app/components/profile/avatar'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'

module.exports = class ChannelParticipantsAvatarsView extends React.Component

  @propTypes =
    shouldTooltipRender : React.PropTypes.bool
    isNicknameVisible   : React.PropTypes.bool
    className           : React.PropTypes.string
    participants        : React.PropTypes.instanceOf immutable.Map


  @defaultProps =
    className           : ''
    shouldTooltipRender : no
    isNicknameVisible   : no
    participants        : immutable.Map()


  renderNickname: (participant, isNicknameVisible)->

    return  if isNicknameVisible is no

    nickname = participant.getIn ['profile', 'nickname']
    <span>{nickname}</span>


  renderTooltip: (participant, shouldTooltipRender) ->

    return  unless shouldTooltipRender

    nickname = participant.getIn ['profile', 'nickname']

    <Tooltip text={nickname} position='bottom' />


  renderChildren: ->

    { participants, isNicknameVisible, shouldTooltipRender } = @props

    participants.toList().map (participant) =>
      <ProfileLinkContainer
        key={participant.get '_id'}
        account={participant.toJS()}
        className='ChannelParticipantAvatars-singleBox'>
        <div>
          <Avatar
            className='ChannelParticipantAvatars-avatar'
            width={30}
            account={participant.toJS()}
            height={30} />
          {@renderNickname participant, isNicknameVisible }
          {@renderTooltip participant, shouldTooltipRender}
        </div>
      </ProfileLinkContainer>


  render: ->

    return null  unless @props.participants.size

    <div className={kd.utils.curry 'AvatarsViewContainer', @props.className}>
      {@renderChildren()}
    </div>


