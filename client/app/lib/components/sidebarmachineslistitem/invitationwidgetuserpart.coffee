React                 = require 'kd-react'
Link                  = require 'app/components/common/link'
Avatar                = require 'app/components/profile/avatar'
ProfileText           = require 'app/components/profile/profiletext'
ProfileLinkContainer  = require 'app/components/profile/profilelinkcontainer'


module.exports = class InvitationWidgetUserPart extends React.Component

  @defaultProps =
    size      :
      width   : 30
      height  : 30


  render: ->

    { owner, size : { width, height } } = @props

    <div className='SidebarWidget-UserView'>
      <ProfileLinkContainer origin={owner}>
        <Avatar className="ChatItem-Avatar" width={width} height={height} />
      </ProfileLinkContainer>

      <ProfileLinkContainer origin={owner} className='SidebarWidget-UserDetail'>
        <ProfileText className='SidebarWidget-FullName' />
        <div className='SidebarWidget-Nickname'>
          @{owner}
        </div>
      </ProfileLinkContainer>
    </div>
