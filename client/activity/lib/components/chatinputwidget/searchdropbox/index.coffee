kd                = require 'kd'
React             = require 'kd-react'
ReactDOM          = require 'react-dom'
immutable         = require 'immutable'
classnames        = require 'classnames'
PortalDropbox     = require 'activity/components/dropbox/portaldropbox'
DropboxItem       = require 'activity/components/dropboxitem'
ErrorDropboxItem  = require '../errordropboxitem'
SearchDropboxItem = require './item'
ScrollableDropbox = require 'activity/components/dropbox/scrollabledropbox'

class SearchDropbox extends React.Component

  @propTypes =
    query           : React.PropTypes.string
    items           : React.PropTypes.instanceOf immutable.List
    selectedItem    : React.PropTypes.instanceOf immutable.Map
    selectedIndex   : React.PropTypes.number
    flags           : React.PropTypes.instanceOf immutable.Map
    onItemSelected  : React.PropTypes.func
    onItemConfirmed : React.PropTypes.func
    onClose         : React.PropTypes.func


  @defaultProps =
    query           : ''
    items           : immutable.List()
    selectedItem    : null
    selectedIndex   : 0
    flags           : null
    onItemSelected  : kd.noop
    onItemConfirmed : kd.noop
    onClose         : kd.noop


  shouldComponentUpdate: (nextProps, nextState) -> not nextProps.flags?.get 'isLoading'


  updatePosition: (inputDimensions) ->

    @refs.dropbox.setInputDimensions inputDimensions


  renderList: ->

    { items, selectedIndex, onItemSelected, onItemConfirmed } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <SearchDropboxItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { onItemSelected }
        onConfirmed = { onItemConfirmed }
        key         = { item.getIn ['message', 'id'] }
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

    { items, query, flags } = @props

    isError      = items.size is 0 and Boolean query
    isEmptyQuery = not query

    <PortalDropbox
      className = 'SearchDropbox'
      visible   = { items.size > 0 or isError or isEmptyQuery }
      onClose   = { @props.onClose }
      type      = 'dropup'
      title     = 'Search'
      ref       = 'dropbox'
    >
      { @renderEmptyQueryMessage()  if isEmptyQuery }
      { @renderError()  if isError }
      { @renderList()  unless isError and isEmptyQuery }
    </PortalDropbox>


module.exports = ScrollableDropbox SearchDropbox
