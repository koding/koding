kd                    = require 'kd'
React                 = require 'kd-react'
ReactDOM              = require 'react-dom'
classnames            = require 'classnames'
immutable             = require 'immutable'
EmojiSelectBoxItem    = require 'activity/components/emojiselectboxitem'
ImmutableRenderMixin  = require 'react-immutable-render-mixin'
List                  = require 'app/components/list'

module.exports = class EmojiSelectBoxList extends React.Component

  @defaultProps =
    items            : immutable.List()
    showEmptySection : no


  numberOfSections: ->

    return @props.items.size


  numberOfRowsInSection: (sectionIndex) ->

    return @props.items.getIn([sectionIndex, 'emojis']).size


  sectionId: (sectionIndex) ->

    category = @props.items.getIn [sectionIndex, 'category']
    return "EmojiSelectBoxCategory-#{kd.utils.slugify category}"


  getSectionAnchorByIndex: (sectionIndex) ->

    return document.getElementById @sectionId sectionIndex


  renderSectionHeaderAtIndex: (sectionIndex) ->

    { showEmptySection, items } = @props
    category = items.getIn [sectionIndex, 'category']

    return  unless items.getIn([sectionIndex, 'emojis']).size or showEmptySection

    <header id={@sectionId sectionIndex} className='EmojiSelectBox-categorySectionHeader'>
      {category}
    </header>


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    { items } = @props

    emojis     = items.getIn [sectionIndex, 'emojis']
    item       = emojis.get rowIndex

    <EmojiSelectBoxItem
      item         = { item }
      index        = { helper.calculateTotalIndex items, sectionIndex, rowIndex }
      onSelected   = { @props.onItemSelected }
      onUnselected = { @props.onItemUnselected }
      onConfirmed  = { @props.onItemConfirmed }
      key          = { item }
    />


  renderEmptySectionAtIndex: (sectionIndex) ->

    return  unless @props.showEmptySection
    <div className='EmojiSelectBox-emptyCategory'>No emoji found</div>


  render: ->

    <List
      numberOfSections={@bound 'numberOfSections'}
      numberOfRowsInSection={@bound 'numberOfRowsInSection'}
      renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      sectionClassName='EmojiSelectBox-categorySection'
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
    />


  helper =

    calculateTotalIndex: (categoryItems, categoryIndex, emojiIndex) ->

      categoryItems = categoryItems.toJS()
      totalIndex    = emojiIndex

      for categoryItem, index in categoryItems when index < categoryIndex
        totalIndex += categoryItem.emojis.length

      return totalIndex


EmojiSelectBoxList.include [ImmutableRenderMixin]

