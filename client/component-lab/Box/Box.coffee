React = require 'react'
generateClassName = require 'classnames'
{ PropTypes } = React

classes = require './Box.stylus'

Box = ({ type, border, children, content }) ->
  className = generateClassName [
    classes[type]
    border and classes['border']
    border and classes["border-#{border}"]
    content and classes['content']
  ]
  <div className={className}>{children}</div>

Box.propTypes =
  type: PropTypes.string
  border: PropTypes.number
  content: PropTypes.bool

Box.defaultProps =
  type: 'default'
  border: 0
  content: yes

module.exports = Box

