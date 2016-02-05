kd                   = require 'kd'
immutable            = require 'immutable'
React                = require 'kd-react'
KDReactorMixin       = require 'app/flux/base/reactormixin'
ActivityFlux         = require 'activity/flux'
ChannelThreadHeader  = require 'activity/components/channelthreadheader'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
PublicChatPane       = require 'activity/components/publicchatpane'
AppearIn             = require 'app/components/appearin'
HeaderView           = require './headerview'
getGroup             = require 'app/util/getGroup'
nick                 = require 'app/util/nick'
classnames           = require 'classnames'


module.exports = class CollaborationPane extends React.Component

  {getters} = ActivityFlux


  channel: (args...) -> @state.channelThread?.getIn ['channel', args...]


  getDataBindings: ->
    return {
      channelThread       : getters.channelThreadById @props.channelId
      channelParticipants : getters.channelParticipantsById @props.channelId
    }


  onVideoStart: ->

    value = "@#{nick()} just joined the video session."

    ActivityFlux.actions.channel.startVideo @channel('id')
    ActivityFlux.actions.message.createMessage @channel('id'), value


  onVideoEnd: ->

    value = "@#{nick()} just left the video session."

    ActivityFlux.actions.channel.endVideo @channel('id')
    ActivityFlux.actions.message.createMessage @channel('id'), value


  onNewParticipantClick: ->

    @refs.pane.onInviteClick()


  renderHeader: ->

    return  unless thread = @state.channelThread

    <HeaderView
      className="ChannelThreadPane-header"
      thread={thread}
      participants={@state.channelParticipants}
      collaborationLink={@props.collaborationLink}
      isVideoActive={thread.getIn ['flags', 'isVideoActive']}
      onNewParticipantButtonClick={@bound 'onNewParticipantClick'}
      onVideoStart={@bound 'onVideoStart'}
      onVideoEnd={@bound 'onVideoEnd'} />


  renderVideo: ->

    isVideoActive = @state.channelThread.getIn ['flags', 'isVideoActive']

    videoName = "koding-#{getGroup().slug}-#{@channel 'id'}"

    <div className="ChannelThreadPane-videoContainer">
      {if isVideoActive then <AppearIn.Container name={videoName} />}
    </div>


  renderBody: ->

    return  unless thread = @state.channelThread

    <div className="ChannelThreadPane-body">
      <section className='ThreadPane-chatWrapper'>
        <PublicChatPane ref='pane' thread={thread}/>
      </section>
    </div>


  renderContent: ->
    <div className='ChannelThreadPane-content'>
      {@renderHeader()}
      {@renderVideo()}
      {@renderBody()}
    </div>


  render: ->

    className = classnames
      'Reactivity ChannelThreadPane': yes
      'is-withVideo': @state.channelThread.getIn ['flags', 'isVideoActive']
      'CollaborationPane is-withChat': yes

    <div className='Reactivity ChannelThreadPane CollaborationPane is-withChat'>
      {@renderContent()}
      {@props.children}
    </div>


CollaborationPane.include [
  KDReactorMixin, ImmutableRenderMixin
]
