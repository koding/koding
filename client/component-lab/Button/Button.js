import React, { PropTypes } from 'react'
import classNames from 'classnames'

import classes from './Button.styl'

const Button = ({ type, size, disabled, auto, children }) => {
  type = type === 'primary' ? 'primary-1' : type

  const className = classNames(
    classes[type],
    classes[size],
    { [classes['disabled']]: !!disabled, [classes['auto']]: !!auto }
  )

  return (
    <button className={className}>{children}</button>
  )
}

Button.propTypes = {
  type: PropTypes.oneOf([
    'primary-1',
    'primary-2',
    'primary-3',
    'primary-4',
    'primary-5',
    'primary-6',
    'primary',
    'secondary',
    'secondary-on-dark'
  ]),
  size: PropTypes.oneOf([
    'small',
    'medium',
    'large',
    'xlarge'
  ]),
  disabled: PropTypes.bool,
  auto: PropTypes.bool,
}

Button.defaultProps = {
  type: 'primary',
  size: 'medium',
  disabled: false,
  auto: false,
}

export default Button
