kd           = require 'kd'
View         = require './view'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
KeyboardKeys = require 'app/constants/keyboardKeys'

module.exports = class CommentInputWidgetContainer extends React.Component

  @propTypes =
    hasValue     : React.PropTypes.bool
    cancelEdit   : React.PropTypes.func
    commentValue : React.PropTypes.string.isRequired
    postComment  : React.PropTypes.func.isRequired
    onChange     : React.PropTypes.func.isRequired


  @defaultProps =
    hasValue     : no
    cancelEdit   : kd.noop


  constructor: (props) ->

    super

    @state = { focusOnInput : no }


  componentDidMount: ->

    textInput = ReactDOM.findDOMNode @refs.view.refs.textInput
    kd.utils.moveCaretToEnd textInput


  onFocus: (event) -> @setState { focusOnInput: yes }


  onBlur: (event) -> @setState { focusOnInput: no }


  onKeyDown: (event) ->

    if event.which is KeyboardKeys.ESC
      @props.cancelEdit()


  render: ->

    <View
      ref          = 'view'
      hasValue     = { @props.hasValue }
      onBlur       = { @bound 'onBlur' }
      onFocus      = { @bound 'onFocus' }
      onKeyDown    = { @bound 'onKeyDown' }
      postComment  = { @props.postComment }
      commentValue = { @props.commentValue }
      focusOnInput = { @state.focusOnInput }
      onChange     = { @props.onChange } />
