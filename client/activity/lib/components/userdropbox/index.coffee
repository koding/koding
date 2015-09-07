kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
ActivityFlux         = require 'activity/flux'
Dropbox              = require 'activity/components/dropbox'
UserDropboxItem      = require 'activity/components/userdropboxitem'
DropboxWrapperMixin  = require 'activity/components/dropbox/dropboxwrappermixin'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class UserDropbox extends React.Component

  @include [ImmutableRenderMixin, DropboxWrapperMixin]


  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedIndex  : 0
    selectedItem   : null


  formatSelectedValue: -> "@#{@props.selectedItem.getIn ['profile', 'nickname']}"


  getItemKey: (item) -> item.get '_id'


  close: ->

    { stateId } = @props
    ActivityFlux.actions.user.setChatInputUsersVisibility stateId, no


  moveToNextPosition: (keyInfo) ->

    if keyInfo.isRightArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ActivityFlux.actions.user.moveToNextChatInputUsersIndex stateId

    return yes


  moveToPrevPosition: (keyInfo) ->

    if keyInfo.isLeftArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ActivityFlux.actions.user.moveToPrevChatInputUsersIndex stateId

    return yes


  checkTextForQuery: (textData) ->

    { currentWord } = textData
    return no  unless currentWord

    matchResult = currentWord.match /^@(.*)/
    return no  unless matchResult

    query = matchResult[1]
    { stateId } = @props
    ActivityFlux.actions.user.setChatInputUsersQuery stateId, query
    ActivityFlux.actions.user.setChatInputUsersVisibility stateId, yes

    return yes


  onItemSelected: (index) ->

    { stateId } = @props
    ActivityFlux.actions.user.setChatInputUsersSelectedIndex stateId, index


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <UserDropboxItem
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
      className      = 'UserDropbox'
      visible        = { @isActive() }
      onOuterClick   = { @bound 'close' }
      direction      = 'up'
      ref            = 'dropbox'
    >
      <div className="Dropbox-innerContainer">
        <div className="Dropbox-header">
          People
        </div>
        <div className="UserDropbox-list">
          {@renderList()}
        </div>
      </div>
    </Dropbox>

