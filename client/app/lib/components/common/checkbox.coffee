_ = require 'lodash'
kd = require 'kd'
React = require 'app/react'

module.exports = class CheckBox extends React.Component

  @propTypes =
    checked: React.PropTypes.bool.isRequired
    onChange: React.PropTypes.func
    onClick: React.PropTypes.func

  @defaultProps =
    onChange: kd.noop
    onClick: kd.noop


  render: ->
    props = _.omit @props, ['onClick', 'className']

    <div className='kdcustomcheckbox'>
      <input
        type='checkbox'
        className={kd.utils.curry 'kdinput checkbox', @props.className}
        {...props} />
      <label onClick={@props.onClick}></label>
    </div>
