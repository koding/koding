React = require 'react'
generateClassName = require 'classnames'
{ PropTypes } = React

textStyles = require './Text.stylus'

Label = ({ size, type, children, monospaced }) ->
  className = generateClassName [
    'Label'
    textStyles['Label']
    textStyles[size]
    type and textStyles[type]
    monospaced and textStyles.monospaced
  ]

  style = if 'number' is typeof size then { fontSize: size } else {}

  return (
    <span className={className}>{children}</span>
  )

Label.propTypes =
  size: PropTypes.oneOfType [
      PropTypes.string
      PropTypes.number
    ]
  type: PropTypes.string

Label.defaultProps =
  size: 'medium'

module.exports = Label
