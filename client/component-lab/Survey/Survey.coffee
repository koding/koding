kd = require 'kd'
React = require 'react'

module.exports = class Survey extends React.Component

  @propTypes =
    className: React.PropTypes.string
    onClick: React.PropTypes.func

  @defaultProps =
    className: ''
    onClick: kd.noop

  render: ->

    className = kd.utils.curry 'Survey', @props.className

    <div className={className}>
      <div className='Survey-free'></div>
      <div className='Survey-detail'></div>
      <button onClick={@props.onClick}>TAKE SURVEY</button>
    </div>
