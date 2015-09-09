kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
Dropbox              = require 'activity/components/dropbox'
SearchDropboxItem    = require 'activity/components/searchdropboxitem'
DropboxWrapperMixin  = require 'activity/components/dropbox/dropboxwrappermixin'
ChatInputFlux        = require 'activity/flux/chatinput'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class SearchDropbox extends React.Component

  @include [ ImmutableRenderMixin, DropboxWrapperMixin ]


  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedItem   : null
    selectedIndex  : 0


  formatSelectedValue: -> @props.selectedItem.get('message').toJS()


  getItemKey: (item) -> item.getIn ['message', 'id']


  close: ->

    { stateId } = @props
    ChatInputFlux.actions.search.setVisibility stateId, no
    ChatInputFlux.actions.search.resetData stateId


  moveToNextPosition: (keyInfo) ->

    return no  if keyInfo.isRightArrow

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.search.moveToNextIndex stateId

    return yes


  moveToPrevPosition: (keyInfo) ->

    return no  if keyInfo.isLeftArrow

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.search.moveToPrevIndex stateId

    return yes


  checkTextForQuery: (textData) ->

    { value } = textData

    matchResult = value.match /\/s (.+)/
    return no  unless matchResult

    query = matchResult[1]
    { stateId } = @props
    ChatInputFlux.actions.search.setQuery stateId, query
    ChatInputFlux.actions.search.setVisibility stateId, yes

    return yes


  onItemSelected: (index) ->

    { stateId } = @props
    ChatInputFlux.actions.search.setSelectedIndex stateId, index


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <SearchDropboxItem
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
      className      = 'SearchDropbox'
      visible        = { @isActive() }
      onOuterClick   = { @bound 'close' }
      direction      = 'up'
      ref            = 'dropbox'
    >
      <div className="Dropbox-innerContainer">
        {@renderList()}
      </div>
    </Dropbox>

