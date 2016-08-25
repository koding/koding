React = require 'react'
generateClassName = require 'classnames'
{ PropTypes } = React

textStyles = require './Text.stylus'

Label = ({ size, type, children }) ->
  className = generateClassName [
    textStyles['Label']
    textStyles[size]
    type and textStyles[type]
  ]

  return (
    <span className={className}>{children}</span>
  )

Label.propTypes =
  size: PropTypes.string
  type: PropTypes.string

Label.defaultProps =
  size: 'medium'

module.exports = Label
