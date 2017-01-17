_ = require 'lodash'
{ PropTypes } = React = require 'react'
{ MaskedInput } = require 'react-text-mask'
{ Field } = require 'redux-form'
classNames = require 'classnames'

styles = require './Input.stylus'

module.exports = Input = (props) ->

  { className, size, disabled, error
    type, auto, title, mask, name } = props

  className = classNames [
    className
    styles['Input']
    styles[size]
    error and styles.danger
    disabled and styles.disabled
    auto and styles.auto
    mask and styles.masked
  ]

  props = _.omit props, ['size', 'auto', 'title', 'error']

  props = _.assign {}, props, { type, className }

  Component = if props.mask then MaskedInput else 'input'

  <div className={styles.wrapper}>
    {<label className={styles.title} htmlFor={props.name}>{title}</label>  if title}
    <Component {...props} />
  </div>


Input.Field = (props) ->
  <Field {...props} component={InputForField} />


InputForField = (props) ->
  { input, meta: { error } } = props

  props = _.assign(
    # remove special props from props. This will result in the real props we
    # passed to the `Input.Field` component.
    _.omit(props, ['input', 'meta'])
    # merge it with input props.
    input
  )

  <Input {...props} error={error} />


Input.propTypes =
  size: PropTypes.oneOf [
    'small', 'medium', 'large'
  ]
  type: PropTypes.string
  auto: PropTypes.bool
  disabled: PropTypes.bool


Input.defaultProps =
  size: 'medium'
  type: 'text'
  auto: on
  disabled: off
