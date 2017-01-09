kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'
{ Provider } = require 'react-redux'

InvoicesList = require './components/invoiceslist'

module.exports = class HomeTeamInvoicesList extends ReactView

  constructor: (options = {}, data) ->

    options.cssClass = 'HomeAppView--section HomeTeamInvoicesList'

    super options, data


  renderReact: ->
    <Provider store={kd.singletons.store}>
      <InvoicesList.Container />
    </Provider>
