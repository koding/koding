kd                      = require 'kd'
React                   = require 'kd-react'
immutable               = require 'immutable'
Link                    = require 'app/components/common/link'
InstallKdModal          = require 'app/providers/managed/installkdmodal'
isGroupChannel          = require 'app/util/isgroupchannel'
Scroller                = require 'app/components/scroller'
ChannelParticipants     = require 'activity/components/channelparticipants'
ThreadSidebarContentBox = require 'activity/components/threadsidebarcontentbox'

module.exports = class ThreadSidebar extends React.Component

  @defaultProps =
    channelThread: immutable.Map()
    messageThread: immutable.Map()
    channelParticipants: immutable.Map()


  showKdModal: -> new InstallKdModal


  renderInviteSection: ->

    return  unless @props.channelThread and @props.channelParticipants

    { channel } = @props.channelThread.toJS()

    if @props.channelParticipants.size or not isGroupChannel channel
      return <ChannelParticipants.Container
        channelThread={@props.channelThread}
        participants={@props.channelParticipants} />

    return  unless channel.typeConstant is 'topic'

    <p className="ThreadSidebarContentBox-info--inviteTeammates">
      <label>You didn&apos;t invite your team yet!</label>
      <a href="/Admin/Invitations">Invite your teammates</a>
    </p>


  renderKdSection: ->
    <Link className='show-kd-modal' onClick={@bound 'showKdModal'}>
      <span className="new">New!</span> <span>Use your local IDE with your Koding VMs</span>
    </Link>


  render: ->
    <Scroller className="ThreadSidebar">
      <ThreadSidebarContentBox title="PARTICIPANTS">
        {@renderInviteSection()}
      </ThreadSidebarContentBox>
      <ThreadSidebarContentBox className="dnd-collaborate" title="SHARED VMs & COLLABORATION">
        <p className="ThreadSidebarContentBox-info">Drag a VM to share it with your teammates</p>
        <p className="ThreadSidebarContentBox-info">Drag a Workspace to collaborate</p>
      </ThreadSidebarContentBox>

      <ThreadSidebarContentBox className="kd" title="TOOLS">
        {@renderKdSection()}
      </ThreadSidebarContentBox>

      <ThreadSidebarContentBox className="help-support" title="HELP & SUPPORT">
        <a href="https://koding.com/docs/collaboration/">Using collaboration</a>
        <a href="https://koding.com/docs/topic/ssh/">How to ssh into your VMs?</a>
        <a href="https://koding.com/docs"><i>See more...</i></a>
      </ThreadSidebarContentBox>
    </Scroller>
