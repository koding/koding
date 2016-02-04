kd                = require 'kd'
IDEPane           = require './idepane'
ReactView         = require 'app/react/reactview'
React             = require 'kd-react'
CollaborationPane = require 'ide/components/collaborationpane'


module.exports = class IDECollaborationPane extends IDEPane

  constructor: (options = {}, data) ->

    options.cssClass = 'ide-collab-pane'

    super options, data

    @addSubView new CollaborationPaneReactView options

    @once 'viewAppended', => @parent.tabHandle.setClass 'ide-collab-pane-handle'



class CollaborationPaneReactView extends ReactView

  renderReact: ->
    <CollaborationPane channelId={@getOptions().channelId} />
