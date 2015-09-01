kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
ActivityFlux         = require 'activity/flux'
Dropup               = require 'activity/components/dropup'
SearchDropupItem     = require 'activity/components/searchdropupitem'
DropupWrapperMixin   = require 'activity/components/dropup/dropupwrappermixin'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class SearchDropup extends React.Component

  @include [ ImmutableRenderMixin, DropupWrapperMixin ]


  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedItem   : null
    selectedIndex  : 0


  formatSelectedValue: -> @props.selectedItem.get('message').toJS()


  getItemKey: (item) -> item.getIn ['message', 'id']


  close: ->

    { actionInitiatorId } = @props
    ActivityFlux.actions.chatInputSearch.setVisibility actionInitiatorId, no
    ActivityFlux.actions.chatInputSearch.resetData actionInitiatorId


  moveToNextPosition: (keyInfo) ->

    return no  if keyInfo.isRightArrow

    { actionInitiatorId } = @props
    unless @hasSingleItem()
      ActivityFlux.actions.chatInputSearch.moveToNextIndex actionInitiatorId

    return yes


  moveToPrevPosition: (keyInfo) ->

    return no  if keyInfo.isLeftArrow

    { actionInitiatorId } = @props
    unless @hasSingleItem()
      ActivityFlux.actions.chatInputSearch.moveToPrevIndex actionInitiatorId

    return yes


  checkTextForQuery: (textData) ->

    { value } = textData

    matchResult = value.match /\/s (.+)/
    return no  unless matchResult

    query = matchResult[1]
    { actionInitiatorId } = @props
    ActivityFlux.actions.chatInputSearch.setQuery actionInitiatorId, query
    ActivityFlux.actions.chatInputSearch.setVisibility actionInitiatorId, yes

    return yes


  onItemSelected: (index) ->

    { actionInitiatorId } = @props
    ActivityFlux.actions.chatInputSearch.setSelectedIndex actionInitiatorId, index


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <SearchDropupItem
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
      className      = "SearchDropup"
      visible        = { @isActive() }
      onOuterClick   = { @bound 'close' }
      ref            = 'dropup'
    >
      <div className="Dropup-innerContainer">
        {@renderList()}
      </div>
    </Dropup>

