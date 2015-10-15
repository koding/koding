kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
Dropbox              = require 'activity/components/dropbox/portaldropbox'
DropboxItem          = require 'activity/components/dropboxitem'
ErrorDropboxItem     = require 'activity/components/errordropboxitem'
SearchDropboxItem    = require 'activity/components/searchdropboxitem'
DropboxWrapperMixin  = require 'activity/components/dropbox/dropboxwrappermixin'
ChatInputFlux        = require 'activity/flux/chatinput'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
isWithinCodeBlock    = require 'app/util/isWithinCodeBlock'


module.exports = class SearchDropbox extends React.Component

  @include [ ImmutableRenderMixin, DropboxWrapperMixin ]


  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedItem   : null
    selectedIndex  : 0
    flags          : immutable.Map()


  shouldComponentUpdate: (nextProps, nextState) -> not nextProps.flags?.get 'isLoading'


  isActive: -> @props.visible


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

    { currentWord, value, position } = textData

    matchResult = value.match /^\/s(earch)? (.*)/
    return no  unless matchResult
    return no  if isWithinCodeBlock value, position

    query = matchResult[2]
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


  renderError: ->

    { query } = @props

    <ErrorDropboxItem>
      { query } not found
    </ErrorDropboxItem>


  renderEmptyQueryMessage: ->

    <DropboxItem className="DropboxItem-singleLine">
      nothing found yet, continue typing...
    </DropboxItem>


  render: ->

    { items, query, flags, visible } = @props

    isError      = items.size is 0 and query
    isEmptyQuery = not query and visible

    <Dropbox
      className = 'SearchDropbox'
      visible   = { @isActive() }
      onClose   = { @bound 'close' }
      type      = 'dropup'
      title     = 'Search'
      ref       = 'dropbox'
    >
      { @renderEmptyQueryMessage()  if isEmptyQuery }
      { @renderError()  if isError }
      { @renderList()  unless isError and isEmptyQuery }
    </Dropbox>

