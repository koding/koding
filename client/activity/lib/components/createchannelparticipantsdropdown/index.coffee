kd                                    = require 'kd'
React                                 = require 'kd-react'
immutable                             = require 'immutable'
Dropbox                               = require 'activity/components/dropbox/relativedropbox'
DropboxWrapperMixin                   = require 'activity/components/dropbox/dropboxwrappermixin'
CreateChannelFlux                     = require 'activity/flux/createchannel'
CreateChannelParticipantsDropdownItem = require './createchannelparticipantsdropdownitem'

module.exports = class CreateChannelParticipantsDropdown extends React.Component

  @include [DropboxWrapperMixin]

  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedIndex  : 0
    selectedItem   : null

  moveToPrevAction     : CreateChannelFlux.actions.user.moveToPrevIndex

  moveToNextAction     : CreateChannelFlux.actions.user.moveToNextIndex

  onItemSelectedAction : CreateChannelFlux.actions.user.setSelectedIndex

  closeAction          : CreateChannelFlux.actions.user.setDropdownVisibility


  # this method overrides DropboxWrapperMixin-getItemKey method to get item by _id instead of id.
  getItemKey: (item) -> item.get '_id'


  formatSelectedValue: -> "@#{@props.selectedItem.getIn ['profile', 'nickname']}"


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <CreateChannelParticipantsDropdownItem
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
      className = "ChannelParticipantsDropdown CreateChannel-dropbox"
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
