kd                           = require 'kd'
React                        = require 'kd-react'
immutable                    = require 'immutable'
classnames                   = require 'classnames'
ActivityFlux                 = require 'activity/flux'
Dropup                       = require 'activity/components/dropup'
SearchDropupItem             = require 'activity/components/searchdropupitem'
KeyboardNavigatedDropupMixin = require 'activity/components/dropup/keyboardnavigateddropupmixin'
KeyboardScrolledDropupMixin  = require 'activity/components/dropup/keyboardscrolleddropupmixin'
ImmutableRenderMixin         = require 'react-immutable-render-mixin'


module.exports = class SearchDropup extends React.Component

  @include [ ImmutableRenderMixin, KeyboardNavigatedDropupMixin, KeyboardScrolledDropupMixin ]


  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : null


  formatSelectedValue: -> @props.selectedItem.get('message').toJS()


  getItemKey: (item) -> item.getIn ['message', 'id']


  close: -> ActivityFlux.actions.chatInputSearch.setVisibility no


  requestNextIndex: -> ActivityFlux.actions.chatInputSearch.moveToNextIndex()


  requestPrevIndex: -> ActivityFlux.actions.chatInputSearch.moveToPrevIndex()


  checkTextForQuery: (textData) ->

    { value } = textData

    matchResult = value.match /\/s(.+)/
    if matchResult
      query = matchResult[1]
      ActivityFlux.actions.chatInputSearch.setQuery query
      ActivityFlux.actions.chatInputSearch.setVisibility yes
      return yes


  onItemSelected: (index) ->

    ActivityFlux.actions.chatInputSearch.setSelectedIndex index


  renderList: ->

    { items, selectedItem } = @props

    items.map (item, index) =>
      isSelected = item is selectedItem

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
