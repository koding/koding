kd        = require 'kd'
React     = require 'kd-react'
ReactView = require 'app/react/reactview'

TopicChatPane = require './index'

module.exports = class TopicChatPaneView extends kd.TabPaneView

  open: ->
  isPageAtBottom: -> no
  viewAppended: ReactView::viewAppended

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'message-pane TopicChatPaneView', options.cssClass

    super options, data


  renderReact: ->
    <TopicChatPane channel={@data} />


