kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

InvoicesList = require './components/invoiceslist'

module.exports = class HomeTeamInvoicesList extends ReactView

  constructor: (options = {}, data) ->

    options.cssClass = 'HomeAppView--section HomeTeamInvoicesList'

    super options, data


  renderReact: -> <InvoicesList.Container />



