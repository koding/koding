kd = require 'kd'
React = require 'kd-react'
ReactSpinner = require 'react-spinner'

module.exports = class Spinner extends React.Component
  render: ->
    <ReactSpinner />