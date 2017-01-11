React = require 'app/react'
ReactView = require 'app/react/reactview'
kd = require 'kd'
{ Provider } = require 'react-redux'
AddOnDeactivation = require './components/addondeactivation'

module.exports = class HomeBusinessAddOnDeactivation extends ReactView

  constructor: (options = {}, data) ->

    super options, data


  renderReact: ->

    <Provider store={kd.singletons.store}>
      <AddOnDeactivation />
    </Provider>
