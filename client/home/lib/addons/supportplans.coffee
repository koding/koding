React = require 'app/react'
ReactView = require 'app/react/reactview'
SupportPlans = require './components/supportplans/container'
kd = require 'kd'
{ Provider } = require 'react-redux'

module.exports = class SupportPlansContainer extends ReactView

  renderReact: ->

    <Provider store={kd.singletons.store}>
      <SupportPlans />
    </Provider>
