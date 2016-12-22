React = require 'app/react'
ReactView = require 'app/react/reactview'
BusinessAddOnBanner = require './components/businessaddonbanner'

module.exports = class HomeAddOnBusinessAddOnBanner extends ReactView

  constructor: (options = {}, data) ->

    super options, data


  renderReact: -> <BusinessAddOnBanner.Container />
