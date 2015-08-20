kd                           = require 'kd'
React                        = require 'kd-react'
immutable                    = require 'immutable'
classnames                   = require 'classnames'
ActivityFlux                 = require 'activity/flux'
Dropup                       = require 'activity/components/dropup'
UserDropupItem               = require 'activity/components/userdropupitem'
KeyboardNavigatedDropupMixin = require 'activity/components/dropup/keyboardnavigateddropupmixin'
KeyboardScrolledDropupMixin  = require 'activity/components/dropup/keyboardscrolleddropupmixin'
ImmutableRenderMixin         = require 'react-immutable-render-mixin'


module.exports = class UserDropup extends React.Component

  @include [ImmutableRenderMixin, KeyboardNavigatedDropupMixin, KeyboardScrolledDropupMixin]


  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : null


  formatSelectedValue: -> "@#{@props.selectedItem.getIn ['profile', 'nickname']}"


  getItemKey: (item) -> item.get '_id'


  close: -> ActivityFlux.actions.user.setChatInputUsersVisibility no


  requestNextIndex: -> ActivityFlux.actions.user.moveToNextChatInputUsersIndex()


  requestPrevIndex: -> ActivityFlux.actions.user.moveToPrevChatInputUsersIndex()


  checkTextForQuery: (textData) ->

    { currentWord } = textData

    matchResult = currentWord?.match /^@(.*)/
    if matchResult
      query = matchResult[1]
      ActivityFlux.actions.user.setChatInputUsersQuery query
      ActivityFlux.actions.user.setChatInputUsersVisibility yes
      return yes


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
