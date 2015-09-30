kd                        = require 'kd'
React                     = require 'kd-react'
immutable                 = require 'immutable'
ThreadSidebarContentBox   = require 'activity/components/threadsidebarcontentbox'
ChannelParticipantAvatars = require 'activity/components/channelparticipantavatars'
ChannelMessagesList       = require 'activity/components/channelmessageslist'


module.exports = class ThreadSidebar extends React.Component

  @defaultProps =
    channelThread: immutable.Map()
    messageThread: immutable.Map()
    channelParticipants: immutable.Map()


  render: ->
    <div className="ThreadSidebar">
      <ThreadSidebarContentBox title="Participants">
        <ChannelParticipantAvatars
          channelThread={@props.channelThread}
          participants={@props.channelParticipants} />
      </ThreadSidebarContentBox>
    </div>


