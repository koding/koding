React = require 'react'
generateClassName = require 'classnames'
{ PropTypes } = React

classes = require './Box.stylus'

Box = ({ type, border, radius, children, content, className }) ->
  className = generateClassName [
    classes[type]
    border and classes['border']
    border and classes["border-#{border}"]
    content and classes['content']
    radius and classes['radius']
    className
  ]

  <div className={className}>{children}</div>

Box.propTypes =
  type: PropTypes.string
  border: PropTypes.number
  content: PropTypes.bool
  radius: PropTypes.bool

Box.defaultProps =
  type: 'default'
  border: 0
  content: yes
  radius: yes

module.exports = Box
