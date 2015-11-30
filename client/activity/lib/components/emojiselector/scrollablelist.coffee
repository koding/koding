$                    = require 'jquery'
kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
classnames           = require 'classnames'
immutable            = require 'immutable'
List                 = require './list'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class EmojiSelectorScrollableList extends React.Component

  @defaultProps =
    items        : immutable.List()
    query        : ''
    sectionIndex : -1


  componentDidUpdate: (prevProps, prevState) ->

    { sectionIndex } = @props
    return  if prevProps.sectionIndex is sectionIndex

    dontScrollOnSectionIndexChange = @dontScrollOnSectionIndexChange
    @dontScrollOnSectionIndexChange = no
    return  if dontScrollOnSectionIndexChange

    list = ReactDOM.findDOMNode @refs.scrollable
    return list.scrollTop = 0  if sectionIndex is -1

    kd.utils.defer =>
      list.scrollTop = @sectionPositions[sectionIndex]  if @sectionPositions


  ready: ->

    { items } = @props

    sectionPositions = items.map (sectionItem, sectionIndex) =>
      sectionAnchor = $(@refs.list.getSectionAnchorByIndex sectionIndex)
      sectionTop    = sectionAnchor.position().top

      return sectionTop

    sectionPositions  = sectionPositions.toJS()
    @sectionPositions = sectionPositions


  onScroll: ->

    return  unless @sectionPositions

    fixedHeader = ReactDOM.findDOMNode @refs.fixedHeader
    list        = ReactDOM.findDOMNode @refs.scrollable
    scrollTop   = list.scrollTop

    isFixedHeaderVisible = scrollTop > @sectionPositions[0]
    fixedHeader.classList.toggle 'hidden', not isFixedHeaderVisible

    return  if @props.query

    sectionIndex  = -1
    positions = @sectionPositions
    for position, i in positions
      if scrollTop < position
        sectionIndex = i - 1  if i > 0
        break

    if sectionIndex is -1 and positions[positions.length - 1] <= scrollTop
      sectionIndex = positions.length - 1

    if sectionIndex isnt @props.sectionIndex
      @dontScrollOnSectionIndexChange = yes
      @onSectionChange sectionIndex


  onSectionChange: (sectionIndex) -> @props.onSectionChange? sectionIndex


  onSearch: (event) ->

    { value }    = event.target
    { onSearch } = @props

    onSearch? value


  renderFixedCategoryHeader: ->

    { items, sectionIndex, query } = @props

    index    = if query then 0 else sectionIndex
    category = items.get(index).get 'category'

    <header className='EmojiSelector-categorySectionHeader fixedHeader hidden' ref='fixedHeader'>{category}</header>


  render: ->

    { items, query } = @props

    <div>
      { @renderFixedCategoryHeader() }
      <div className="EmojiSelector-list Dropbox-resizable" ref='scrollable' onScroll={@bound 'onScroll'}>
        <input className='EmojiSelector-searchInput' placeholder='Search' value={query} onChange={@bound 'onSearch'} />
        <List
          items            = { items }
          onItemSelected   = { @props.onItemSelected }
          onItemUnselected = { @props.onItemUnselected }
          onItemConfirmed  = { @props.onItemConfirmed }
          ref              = 'list'
        />
      </div>
    </div>


EmojiSelectorScrollableList.include [ImmutableRenderMixin]

