kd = require 'kd'
React = require 'app/react'
ReactSpinner = require 'react-spinner'

require './styl/spinner.styl'

module.exports = class Spinner extends React.Component
  render: ->
    <ReactSpinner />
