React = require 'app/react'
ReactView = require 'app/react/reactview'
kd = require 'kd'
{ Provider } = require 'react-redux'
SupportPlanDeactivation = require './components/supportplandeactivation'

module.exports = class HomeSupportPlanDeactivation extends ReactView

  constructor: (options = {}, data) ->

    super options, data


  renderReact: ->

    <Provider store={kd.singletons.store}>
      <SupportPlanDeactivation />
    </Provider>
