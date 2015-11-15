kd                   = require 'kd'
React                = require 'kd-react'

module.exports = class AutoSizeTextarea extends React.Component

  @defaultProps =
    rows      : 1
    onResize  : kd.noop
    onChange  : kd.noop


  componentDidUpdate: -> @updateSize()


  onChange: (event) ->

    @updateSize event
    @props.onChange event


  setOverflow: ->

    textarea = React.findDOMNode @refs.textarea
    if textarea.style.height >= textarea.style.maxHeight
      textarea.style.overflowY = 'auto'
    else
      textarea.style.overflowY = 'hidden'


  updateSize: (event) ->

    textarea       = React.findDOMNode @refs.textarea
    style          = window.getComputedStyle(textarea, null)
    originalHeight = style.height
    borderHeight   = parseFloat(style.borderTopWidth) + parseFloat(style.borderBottomWidth)
    textarea.style.height = 'auto'
    lastHeight     = textarea.scrollHeight + borderHeight

    if textarea.scrollHeight is 0
      textarea.style.height  = "#{originalHeight}px"
    else
      textarea.style.height  = "#{lastHeight}px"

    @setOverflow()
    @props.onResize()


  render: ->

    <textarea {...this.props}
      ref      ='textarea'
      onChange = { @bound 'onChange' }
      onInput  = { @bound 'updateSize' }>
      {this.props.children}
    </textarea>