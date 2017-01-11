React = require 'app/react'
ReactView = require 'app/react/reactview'
BusinessAddOnChatlio = require './components/businessaddonchatlio'

module.exports = class HomeAddOnChatlio extends ReactView

  constructor: (options = {}, data) ->

    super options, data


  renderReact: -> <BusinessAddOnChatlio.Container />
