kd                      = require 'kd'
React                   = require 'kd-react'
immutable               = require 'immutable'
classnames              = require 'classnames'
ActivityFlux            = require 'activity/flux'
Dropup                  = require 'activity/components/dropup'
UserDropupItem          = require 'activity/components/userdropupitem'
KeyboardNavigatedDropup = require 'activity/components/dropup/keyboardnavigateddropup'
KeyboardScrolledDropup  = require 'activity/components/dropup/keyboardscrolleddropup'
ImmutableRenderMixin    = require 'react-immutable-render-mixin'


module.exports = class UserDropup extends React.Component

  @include [ImmutableRenderMixin, KeyboardNavigatedDropup, KeyboardScrolledDropup]


  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : null


  formatSelectedValue: -> "@#{@props.selectedItem.getIn ['profile', 'nickname']}"


  getItemKey: (item) -> item.get '_id'


  close: -> ActivityFlux.actions.user.setChatInputUsersVisibility no


  requestNextIndex: -> ActivityFlux.actions.user.moveToNextChatInputUsersIndex()


  requestPrevIndex: -> ActivityFlux.actions.user.moveToPrevChatInputUsersIndex()


  setQuery: (query) ->

    matchResult = query?.match /^@(.*)/
    if matchResult
      query = matchResult[1]
      ActivityFlux.actions.user.setChatInputUsersQuery query
      ActivityFlux.actions.user.setChatInputUsersVisibility yes
    else if @isActive()
      @close()


  onItemSelected: (index) ->

    ActivityFlux.actions.user.setChatInputUsersSelectedIndex index


  renderList: ->

    { items, selectedItem } = @props

    items.map (item, index) =>
      isSelected = item is selectedItem

      <UserDropupItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  render: ->

    <Dropup
      className      = "UserDropup"
      visible        = { @isActive() }
      onOuterClick   = { @bound 'close' }
      ref            = 'dropup'
    >
      <div className="Dropup-innerContainer">
        <div className="Dropup-header">
          People
        </div>
        <div className="UserDropup-list">
          {@renderList()}
        </div>
      </div>
    </Dropup>
