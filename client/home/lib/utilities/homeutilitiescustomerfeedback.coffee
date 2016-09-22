kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'

CustomerFeedBack = require './components/customerfeedback/'

module.exports = class HomeUtilitiesCustomerFeedback extends ReactView

  renderReact: ->
    <CustomerFeedBack.Container />
