React                 = require 'kd-react'
Link                  = require 'app/components/common/link'
Avatar                = require 'app/components/profile/avatar'
ProfileText           = require 'app/components/profile/profiletext'
ProfileLinkContainer  = require 'app/components/profile/profilelinkcontainer'


module.exports = class InvitationWidgetUserView extends React.Component

  @defaultProps =
    size      :
      width   : 30
      height  : 30


  render: ->
    <div className='InvitationWidget-UserView'>
      <ProfileLinkContainer origin={@props.owner}>
        <Avatar className="ChatItem-Avatar" width={@props.size.width} height={@props.size.height} />
      </ProfileLinkContainer>

      <ProfileLinkContainer origin={@props.owner} className='InvitationWidget-UserDetail'>
        <ProfileText className='InvitationWidget-FullName' />
        <div className='InvitationWidget-Nickname'>
          @{@props.owner}
        </div>
      </ProfileLinkContainer>
    </div>
