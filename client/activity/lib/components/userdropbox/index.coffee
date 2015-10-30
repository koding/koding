kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
Dropbox              = require 'activity/components/dropbox/portaldropbox'
UserDropboxItem      = require 'activity/components/userdropboxitem'
DropboxWrapperMixin  = require 'activity/components/dropbox/dropboxwrappermixin'
ChatInputFlux        = require 'activity/flux/chatinput'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
isWithinCodeBlock    = require 'app/util/isWithinCodeBlock'


module.exports = class UserDropbox extends React.Component

  @include [ImmutableRenderMixin, DropboxWrapperMixin]


  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedIndex  : 0
    selectedItem   : null


  formatSelectedValue: -> "@#{helper.getItemName @props.selectedItem}"


  getItemKey: (item) -> helper.getItemName item


  close: ->

    { stateId } = @props
    ChatInputFlux.actions.user.setVisibility stateId, no


  moveToNextPosition: (keyInfo) ->

    if keyInfo.isRightArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.user.moveToNextIndex stateId

    return yes


  moveToPrevPosition: (keyInfo) ->

    if keyInfo.isLeftArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.user.moveToPrevIndex stateId

    return yes


  checkTextForQuery: (textData) ->

    { currentWord, value, position } = textData
    return no  unless currentWord
    return no  if isWithinCodeBlock value, position

    matchResult = currentWord.match /^@(.*)/
    return no  unless matchResult

    query = matchResult[1]
    { stateId } = @props
    ChatInputFlux.actions.user.setQuery stateId, query
    ChatInputFlux.actions.user.setVisibility stateId, yes

    return yes


  onItemSelected: (index) ->

    { stateId } = @props
    ChatInputFlux.actions.user.setSelectedIndex stateId, index


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
      className = 'UserDropbox'
      visible   = { @isActive() }
      onClose   = { @bound 'close' }
      type      = 'dropup'
      title     = 'People'
      ref       = 'dropbox'
    >
      {@renderList()}
    </Dropbox>


  helper =

    getItemName: (item) ->

      if item.get 'isMention'
      then item.get 'name'
      else item.getIn ['profile', 'nickname']