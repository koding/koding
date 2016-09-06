kd        = require 'kd'
React     = require 'kd-react'
ReactView = require 'app/react/reactview'

PublicChatPane = require './index'

module.exports = class PublicChatPaneView extends kd.TabPaneView

  open: ->
  isPageAtBottom: -> no
  viewAppended: ReactView::viewAppended

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'message-pane PublicChatPaneView', options.cssClass

    super options, data


  renderReact: ->
    <PublicChatPane channel={@data} />
