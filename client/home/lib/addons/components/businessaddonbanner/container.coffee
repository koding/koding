React = require 'app/react'
View = require './view'
kd = require 'kd'
{ Provider } = require 'react-redux'

module.exports = class BusinessAddOnBannerContainer extends React.Component

  render: ->

    <Provider store={kd.singletons.store}>
      <View />
    </Provider>
