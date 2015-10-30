kd                        = require 'kd'
React                     = require 'kd-react'
immutable                 = require 'immutable'
ThreadSidebarContentBox   = require 'activity/components/threadsidebarcontentbox'
ChannelParticipantAvatars = require 'activity/components/channelparticipantavatars'
ChannelMessagesList       = require 'activity/components/channelmessageslist'
isGroupChannel            = require 'app/util/isgroupchannel'


module.exports = class ThreadSidebar extends React.Component

  @defaultProps =
    channelThread: immutable.Map()
    messageThread: immutable.Map()
    channelParticipants: immutable.Map()


  renderInviteSection: ->

    return  unless @props.channelThread and @props.channelParticipants

    { channel } = @props.channelThread.toJS()

    if @props.channelParticipants.size or not isGroupChannel channel
      return <ChannelParticipantAvatars
        channelThread={@props.channelThread}
        participants={@props.channelParticipants} />

    return  unless channel.typeConstant is 'topic'

    <p className="ThreadSidebarContentBox-info--inviteTeammates">
      <label>You didn't invite your team yet!</label>
      <a href="/Admin/Invitations">Invite your teammates</a>
    </p>


  render: ->
    <div className="ThreadSidebar">
      <ThreadSidebarContentBox title="PARTICIPANTS">
        {@renderInviteSection()}
      </ThreadSidebarContentBox>
      <ThreadSidebarContentBox className="dnd-collaborate" title="SHARED VMs & COLLABORATION">
        <p className="ThreadSidebarContentBox-info">Drag a VM to share it with your teammates</p>
        <p className="ThreadSidebarContentBox-info">Drag a Workspace to collaborate</p>
      </ThreadSidebarContentBox>
      <ThreadSidebarContentBox className="help-support" title="HELP & SUPPORT">
        <a href="http://learn.koding.com/guides/kdfs">New! Use your own IDEs with KDFS</a>
        <a href="http://learn.koding.com/guides/collaboration/">Using collaboration</a>
        <a href="http://learn.koding.com/categories/ssh/">How to ssh into your VMs?</a>
        <a href="http://learn.koding.com"><i>See more...</i></a>
      </ThreadSidebarContentBox>
    </div>


