React = require 'app/react'
ReactView = require 'app/react/reactview'
BusinessAddOns = require './components/businessaddons/container'
kd = require 'kd'
{ Provider } = require 'react-redux'

module.exports = class BusinessAddOnsContainer extends ReactView

  renderReact: ->

    <Provider store={kd.singletons.store}>
      <BusinessAddOns />
    </Provider>
