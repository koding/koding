kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
ActivityFlux         = require 'activity/flux'
Dropup               = require 'activity/components/dropup'
UserDropupItem       = require 'activity/components/userdropupitem'
DropupWrapperMixin   = require 'activity/components/dropup/dropupwrappermixin'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class UserDropup extends React.Component

  @include [ImmutableRenderMixin, DropupWrapperMixin]


  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedIndex  : 0
    selectedItem   : null
    keyboardScroll : yes


  formatSelectedValue: -> "@#{@props.selectedItem.getIn ['profile', 'nickname']}"


  getItemKey: (item) -> item.get '_id'


  close: ->

    { actionInitiatorId } = @props
    ActivityFlux.actions.user.setChatInputUsersVisibility actionInitiatorId, no


  moveToNextPosition: (keyInfo) ->

    if keyInfo.isRightArrow
      @close()
      return no

    { actionInitiatorId } = @props
    unless @hasSingleItem()
      ActivityFlux.actions.user.moveToNextChatInputUsersIndex actionInitiatorId

    return yes


  moveToPrevPosition: (keyInfo) ->

    if keyInfo.isLeftArrow
      @close()
      return no

    { actionInitiatorId } = @props
    unless @hasSingleItem()
      ActivityFlux.actions.user.moveToPrevChatInputUsersIndex actionInitiatorId

    return yes


  checkTextForQuery: (textData) ->

    { currentWord } = textData
    return no  unless currentWord

    matchResult = currentWord.match /^@(.*)/
    return no  unless matchResult

    query = matchResult[1]
    { actionInitiatorId } = @props
    ActivityFlux.actions.user.setChatInputUsersQuery actionInitiatorId, query
    ActivityFlux.actions.user.setChatInputUsersVisibility actionInitiatorId, yes

    return yes


  onItemSelected: (index) ->

    { actionInitiatorId } = @props
    ActivityFlux.actions.user.setChatInputUsersSelectedIndex actionInitiatorId, index


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

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

