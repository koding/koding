kd                              = require 'kd'
React                           = require 'kd-react'
immutable                       = require 'immutable'
classnames                      = require 'classnames'
ActivityFlux                    = require 'activity/flux'
Dropbox                         = require 'activity/components/dropbox'
DropboxWrapperMixin             = require 'activity/components/dropbox/dropboxwrappermixin'
ChannelParticipantsDropdownItem = require 'activity/components/channelparticipantsdropdownitem'


module.exports = class ChannelParticipantsDropdown extends React.Component

  @include [DropboxWrapperMixin]

  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedIndex  : 0
    selectedItem   : null

  constructor: (props) ->

    super

    { user, channel } = ActivityFlux.actions

    @moveToPrevAction     = user.moveToPrevChannelParticipantIndex
    @moveToNextAction     = user.moveToNextChannelParticipantIndex
    @closeAction          = channel.setChannelParticipantsDropdownVisibility
    @onItemSelectedAction = user.setChannelParticipantsSelectedIndex

  # this method overrides DropboxWrapperMixin-componentDidUpdate handler.
  # In this component, we use dropdown keyword. In DropboxWrapperMixin/componentDidUpdate handler
  # expects dropbox component so it occurs an error. Also this component doesn't need any action when
  # componentDidUpdate event fired.
  componentDidUpdate: ->


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
      className      = "ChannelParticipantsDropdown"
      visible        = { @isActive() }
      onOuterClick   = { @bound 'close' }
      ref            = 'dropbox'
      top            = '100px'
    >
      <div className="Dropdown-innerContainer">
        <div className="ChannelParticipantsDropdown-list">
          {@renderList()}
        </div>
      </div>
    </Dropbox>

