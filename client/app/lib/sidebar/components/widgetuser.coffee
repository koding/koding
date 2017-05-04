React = require 'app/react'
Avatar = require 'app/components/profile/avatar'
ProfileText = require 'app/components/profile/profiletext'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'

module.exports = SidebarWidgetUser = ({ size = {}, owner }) ->

  { width = 36, height = 36 } = size

  <div className='SidebarWidget-UserView'>
    <ProfileLinkContainer origin={owner}>
      <Avatar className="ChatItem-Avatar" width={width} height={height} />
    </ProfileLinkContainer>

    <ProfileLinkContainer origin={owner} className='SidebarWidget-UserDetail'>
      <ProfileText className='SidebarWidget-FullName' />
      <ProfileNick owner={owner} />
    </ProfileLinkContainer>
  </div>


ProfileNick = ({owner}) ->
  <div className='SidebarWidget-Nickname'>
    @{owner}
  </div>
