kd        = require 'kd'
React     = require 'kd-react'
immutable = require 'immutable'
Dropbox   = require 'activity/components/dropbox/relativedropbox'

module.exports = class ChannelParticipantsDropdownView extends React.Component

  @propTypes =
    className           : React.PropTypes.string
    visible             : React.PropTypes.bool
    selectedIndex       : React.PropTypes.number
    onClose             : React.PropTypes.func.isRequired
    onItemSelected      : React.PropTypes.func.isRequired
    confirmSelectedItem : React.PropTypes.func.isRequired
    DropdownItem        : React.PropTypes.func.isRequired
    items               : React.PropTypes.instanceOf immutable.List


  @defaultProps =
    className           : ''
    visible             : no
    selectedIndex       : 0
    items               : immutable.List()


  getItemKey: (item) -> item.get '_id'


  renderList: ->

    { items, selectedIndex, DropdownItem} = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <DropdownItem
        item        = { item }
        index       = { index }
        isSelected  = { isSelected }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
        onSelected  = { @props.onItemSelected }
        onConfirmed = { @props.confirmSelectedItem } />


  render: ->

    <Dropbox
      top       = '100px'
      ref       = 'dropbox'
      visible   = { @props.visible }
      onClose   = { @props.onClose }
      className = { kd.utils.curry 'ChannelParticipantsDropdown', @props.className }>
      <div className="Dropdown-innerContainer">
        <div className="ChannelParticipantsDropdown-list">
          {@renderList()}
        </div>
      </div>
    </Dropbox>
