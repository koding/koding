{ PropTypes } = React = require 'react'
classNames = require 'classnames'

styles = require './Button.stylus'

module.exports = Button = ({ type, size, disabled, auto, children, onClick }) ->
  type = 'primary-1'  if type is 'primary'

  className = classNames [
    styles[type]
    styles[size]
    !!disabled and styles.disabled
    !!auto and styles.auto
  ]

  <button
    onClick={onClick}
    disabled={disabled}
    className={className}>{children}</button>


Button.propTypes =
  auto: PropTypes.bool
  disabled: PropTypes.bool
  onClick: PropTypes.func
  # type: PropTypes.oneOf [
  #   'primary', 'primary-1', 'primary-2', 'primary-3', 'primary-4',
  #   'primary-5', 'primary-6', 'primary', 'secondary', 'secondary-on-dark'
  #   'link-secondary', 'link-primary-1'
  # ]
  size: PropTypes.oneOf [
    'small', 'medium', 'large', 'xlarge'
  ]

Button.defaultProps =
  type: 'primary'
  size: 'medium'
  disabled: no
  auto: no
  onClick: noop

noop = ->
