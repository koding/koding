kd                              = require 'kd'
React                           = require 'kd-react'
immutable                       = require 'immutable'
classnames                      = require 'classnames'
ActivityFlux                    = require 'activity/flux'
Dropbox                         = require 'activity/components/dropbox/relativedropbox'
DropboxWrapperMixin             = require 'activity/components/dropbox/dropboxwrappermixin'
ChannelParticipantsDropdownItem = require 'activity/components/channelparticipantsdropdownitem'


module.exports = class ChannelParticipantsDropdown extends React.Component

  @include [DropboxWrapperMixin]

  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedIndex  : 0
    selectedItem   : null

  moveToPrevAction     : ActivityFlux.actions.user.moveToPrevChannelParticipantIndex

  moveToNextAction     : ActivityFlux.actions.user.moveToNextChannelParticipantIndex

  onItemSelectedAction : ActivityFlux.actions.user.setChannelParticipantsSelectedIndex

  closeAction          : ActivityFlux.actions.channel.setChannelParticipantsDropdownVisibility


  # this method overrides DropboxWrapperMixin-getItemKey method to get item by _id instead of id.
  getItemKey: (item) -> item.get '_id'


  formatSelectedValue: -> "@#{@props.selectedItem.getIn ['profile', 'nickname']}"


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <ChannelParticipantsDropdownItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  render: ->

    <Dropbox
      className = "ChannelParticipantsDropdown"
      visible   = { @isActive() }
      onClose   = { @bound 'close' }
      ref       = 'dropbox'
      top       = '100px'
    >
      <div className="Dropdown-innerContainer">
        <div className="ChannelParticipantsDropdown-list">
          {@renderList()}
        </div>
      </div>
    </Dropbox>

