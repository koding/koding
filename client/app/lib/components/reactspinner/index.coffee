kd = require 'kd'
React = require 'kd-react'
Spinner = require 'react-spinner'

module.exports = class ReactSpinner extends React.Component
  render: ->
    <Spinner />