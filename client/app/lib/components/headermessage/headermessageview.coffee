kd = require 'kd'
React = require 'react'
ReactView = require 'app/react/reactview'
{ Provider } = require 'react-redux'

HeaderMessageContainer = require './container'

module.exports = class HeaderMessageView extends ReactView

  renderReact: ->

    <Provider store={kd.singletons.store}>
      <HeaderMessageContainer />
    </Provider>
