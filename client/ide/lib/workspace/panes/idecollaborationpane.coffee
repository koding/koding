kd                = require 'kd'
IDEPane           = require './idepane'
ReactView         = require 'app/react/reactview'
React             = require 'kd-react'
CollaborationPane = require 'ide/components/collaborationpane'
nick              = require 'app/util/nick'
groupifyLink      = require 'app/util/groupifyLink'


module.exports = class IDECollaborationPane extends IDEPane

  constructor: (options = {}, data) ->

    options.cssClass = 'ide-collab-pane'

    super options, data

    @addSubView new CollaborationPaneReactView options

    @once 'viewAppended', => @parent.tabHandle.setClass 'ide-collab-pane-handle'



class CollaborationPaneReactView extends ReactView

  renderReact: ->
    {channelId, host} = @getOptions()
    collaborationLink = generateCollaborationLink channelId, host
    <CollaborationPane channelId={@getOptions().channelId} collaborationLink={collaborationLink} />


generateCollaborationLink = (channelId, host) ->

  subject = if host is nick()
  then 'my'
  else "#{host}'s"

  return "Click [here](/Collaboration/#{host}/#{channelId}) to join #{subject} collaboration session"

