React         = require 'kd-react'
ChatInputFlux = require 'activity/flux/chatinput'

module.exports = EmojiBoxWrapperMixin =

  componentDidMount: ->

    ChatInputFlux.actions.emoji.loadUsageCounts()


  handleSelectedItemConfirmation: ->

    { selectedItem } = @props
    ChatInputFlux.actions.emoji.incrementUsageCount selectedItem

