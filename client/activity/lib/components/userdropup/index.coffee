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
    selectedItem   : null
    keyboardScroll : yes


  formatSelectedValue: -> "@#{@props.selectedItem.getIn ['profile', 'nickname']}"


  getItemKey: (item) -> item.get '_id'


  close: -> ActivityFlux.actions.user.setChatInputUsersVisibility no


  moveToNextPosition: (keyInfo) ->

    if keyInfo.isRightArrow
      @close()
      return no

    ActivityFlux.actions.user.moveToNextChatInputUsersIndex()  unless @hasSingleItem()
    return yes


  moveToPrevPosition: (keyInfo) ->

    if keyInfo.isLeftArrow
      @close()
      return no

    ActivityFlux.actions.user.moveToPrevChatInputUsersIndex()  unless @hasSingleItem()
    return yes


  checkTextForQuery: (textData) ->

    { currentWord } = textData
    return no  unless currentWord

    matchResult = currentWord.match /^@(.*)/
    return no  unless matchResult

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

