kd        = require 'kd'
View      = require './view'
React     = require 'kd-react'
immutable = require 'immutable'

module.exports = class ChannelParticipantsDropdownItemContainer extends React.Component

  @propTypes =
    isSelected : React.PropTypes.bool
    index      : React.PropTypes.number
    item       : React.PropTypes.instanceOf(immutable.Map).isRequired


  @defaultProps =
    index      : 0
    isSelected : no


  render: ->

    <View {...@props}/>

