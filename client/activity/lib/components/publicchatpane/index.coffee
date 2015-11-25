kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
ActivityFlux         = require 'activity/flux'
ChatPane             = require 'activity/components/chatpane'
ChatInputWidget      = require 'activity/components/chatinputwidget'
ChatPaneWrapperMixin = require 'activity/components/chatpane/chatpanewrappermixin'

module.exports = class PublicChatPane extends React.Component

  @defaultProps =
    thread   : immutable.Map()


  onFollowChannel: ->

    ActivityFlux.actions.channel.followChannel @channel 'id'


  renderFollowChannel: ->

    <div className="PublicChatPane-subscribeContainer">
      This is a preview of <strong>#{@channel 'name'}</strong>
      <button
        ref       = "button"
        className = "Button Button-followChannel"
        onClick   = { @bound 'onFollowChannel' }>
          Join
      </button>
    </div>


  renderFooter: ->

    return null  unless @props.thread?.get 'messages'

    isParticipant = @channel 'isParticipant'

    <footer className="PublicChatPane-footer ChatPaneFooter">
      <div className={unless isParticipant then 'hidden'}>
        <ChatInputWidget
           ref       = 'chatInputWidget'
           onSubmit  = { @bound 'onSubmit' }
           onCommand = { @bound 'onCommand' }
           channelId = { @channel 'id' }
           onResize  = { @bound 'onResize' }/>
      </div>
      <div className={if isParticipant then 'hidden'}>
        { @renderFollowChannel() }
      </div>
    </footer>


  render: ->

    return null  unless @props.thread

    <div>
      <ChatPane
        key            = { @props.thread.get 'channelId' }
        thread         = { @props.thread }
        className      = 'PublicChatPane'
        onSubmit       = { @bound 'onSubmit' }
        onLoadMore     = { @bound 'onLoadMore' }
        onInviteOthers = {@bound 'onInviteOthers'}
        ref            = 'chatPane'
      />
      {@renderFooter()}
    </div>


React.Component.include.call PublicChatPane, [ChatPaneWrapperMixin]

