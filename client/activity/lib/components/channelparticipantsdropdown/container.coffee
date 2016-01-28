kd             = require 'kd'
View           = require './view'
React          = require 'kd-react'
ReactDOM       = require 'react-dom'
immutable      = require 'immutable'
ActivityFlux   = require 'activity/flux'
scrollToTarget = require 'app/util/scrollToTarget'

module.exports = class ChannelParticipantsDropdownContainer extends React.Component

  @propTypes =
    visible              : React.PropTypes.bool
    onItemConfirmed      : React.PropTypes.func
    className            : React.PropTypes.string
    selectedIndex        : React.PropTypes.number
    moveToNextAction     : React.PropTypes.func.isRequired
    moveToPrevAction     : React.PropTypes.func.isRequired
    closeAction          : React.PropTypes.func.isRequired
    onItemSelectedAction : React.PropTypes.func.isRequired
    DropdownItem         : React.PropTypes.func.isRequired
    selectedItem         : React.PropTypes.instanceOf immutable.Map
    items                : React.PropTypes.instanceOf immutable.List


  @defaultProps =
    className            : ''
    visible              : no
    selectedIndex        : 0
    onItemConfirmed      : kd.noop
    items                : immutable.List()
    selectedItem         : immutable.Map()


  componentDidUpdate: (prevProps, prevState) ->

    { selectedItem, visible } = @props

    return  if prevProps.selectedItem is selectedItem or not selectedItem
    return  if visible? and not visible

    containerElement = @refs.view.refs.dropbox.getContentElement()
    itemElement      = ReactDOM.findDOMNode @refs.view.refs[selectedItem.get '_id']

    scrollToTarget containerElement, itemElement


  isActive: ->

    { items, visible } = @props
    visible ?= yes
    return items.size > 0 and visible


  hasSingleItem: -> @props.items.size is 1


  confirmSelectedItem: ->

    selectedValue = @formatSelectedValue()
    @props.onItemConfirmed? selectedValue
    @close()


  moveToPrevPosition: ->

    @props.moveToPrevAction()  unless @hasSingleItem()
    return yes


  moveToNextPosition: ->

    @props.moveToNextAction()  unless @hasSingleItem()
    return yes


  onItemSelected: (index) -> @props.onItemSelectedAction index


  close: -> @props.closeAction no


  formatSelectedValue: -> "@#{@props.selectedItem.getIn ['profile', 'nickname']}"


  render: ->

    <View
      ref                 = 'view'
      visible             = { @isActive() }
      items               = { @props.items }
      onClose             = { @bound 'close' }
      className           = { @props.className }
      DropdownItem        = { @props.DropdownItem }
      selectedIndex       = { @props.selectedIndex }
      onItemSelected      = { @bound 'onItemSelected' }
      confirmSelectedItem = { @bound 'confirmSelectedItem' } />

