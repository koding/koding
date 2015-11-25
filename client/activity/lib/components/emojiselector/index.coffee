$                     = require 'jquery'
kd                    = require 'kd'
React                 = require 'kd-react'
ReactDOM              = require 'react-dom'
classnames            = require 'classnames'
immutable             = require 'immutable'
formatEmojiName       = require 'activity/util/formatEmojiName'
ChatInputFlux         = require 'activity/flux/chatinput'
Dropbox               = require 'activity/components/dropbox/portaldropbox'
EmojiSelectorItem     = require 'activity/components/emojiselectoritem'
EmojiIcon             = require 'activity/components/emojiicon'
List                  = require 'app/components/list'
ImmutableRenderMixin  = require 'react-immutable-render-mixin'


module.exports = class EmojiSelector extends React.Component

  @include [ImmutableRenderMixin]


  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : ''
    query        : ''


  componentDidUpdate: (prevProps, prevState) ->

    { visible, items, query } = @props
    isChangedToRegularMode    = prevProps.query and not query
    isBecomeVisible           = visible and not prevProps.visible

    return  unless @props.visible and (isBecomeVisible or isChangedToRegularMode)

    filtersScrollData = items.map (item) ->
      category = item.get 'category'
      return {
        top : $(helper.findFilterTabByCategory category).position().top
        tab : helper.findFilterTabByCategory category
      }

    filtersScrollData  = filtersScrollData.toJS()
    @filtersScrollData = filtersScrollData


  updatePosition: (inputDimensions) -> @refs.dropbox.setInputDimensions inputDimensions


  onItemSelected: (index) ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setSelectorSelectedIndex stateId, index


  onItemConfirmed: ->

    { selectedItem } = @props
    @props.onItemConfirmed? formatEmojiName selectedItem
    @close()


  close: ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setSelectorVisibility stateId, no


  scrollToCategory: (category) ->

    list = ReactDOM.findDOMNode @refs.list
    return list.scrollTop = 0  unless category

    header    = $(helper.findCategoryHeader category)
    headerTop = header.position().top

    list.scrollTop += headerTop


  onScroll: ->

    return if @props.query

    list      = ReactDOM.findDOMNode @refs.list
    scrollTop = list.scrollTop

    activeTab = helper.findFilterTab 'activeTab'
    activeTab.classList.remove 'activeTab'  if activeTab

    selectedTab = helper.findFilterTabByCategory 'all'
    for scrollItem, i in @filtersScrollData
      if scrollTop < scrollItem.top
        selectedTab = scrollItem.tab[i - 1]  if i > 0
        break

    selectedTab.classList.add 'activeTab'


  onSearch: (event) ->

    { value }   = event.target
    { stateId } = @props

    ChatInputFlux.actions.emoji.setSelectorQuery stateId, value


  numberOfSections: ->

    return @props.items.size


  numberOfRowsInSection: (sectionIndex) ->

    return @props.items.get(sectionIndex).get('emojis').size


  renderSectionHeaderAtIndex: (sectionIndex) ->

    category = @props.items.get(sectionIndex).get 'category'
    <header className={"EmojiSelectorCategory-#{kd.utils.slugify category}"}>{category}</header>


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    { items, selectedItem } = @props

    item       = items.get(sectionIndex).get('emojis').get rowIndex
    isSelected = selectedItem is item

    <EmojiSelectorItem
      item         = { item }
      index        = { helper.calculateTotalIndex items, sectionIndex, rowIndex }
      isSelected   = { isSelected }
      onSelected   = { @bound 'onItemSelected' }
      onConfirmed  = { @bound 'onItemConfirmed' }
      key          = { item }
    />

  renderEmptySectionMessageAtIndex: (sectionIndex) ->

    <div className='EmojiSelector-emptyCategory'>No emoji found</div>


  renderCategoryFilters: ->

    { filters } = @props

    components = filters.map (item) =>
      iconClassName = "emoji-sprite emoji-#{item.get('iconEmoji')}"
      category      = item.get 'category'

      <span className={"categoryFilterTab #{kd.utils.slugify category}"} title={category} onClick={@lazyBound 'scrollToCategory', category} key={category}>
        <span className='emoji-wrapper'>
          <span className={iconClassName}></span>
        </span>
      </span>

    <div className='EmojiSelector-categoryFilters'>
      <span className='categoryFilterTab all' title='All' onClick={@lazyBound 'scrollToCategory', ''}>
        <span className='emoji-wrapper'>
          <span className='emoji-sprite emoji-clock3'></span>
        </span>
      </span>
      { components }
    </div>


  render: ->

    { query, visible, selectedItem } = @props

    <Dropbox
      className = 'EmojiSelector'
      visible   = { visible }
      onClose   = { @bound 'close' }
      type      = 'dropup'
      right     = 0
      ref       = 'dropbox'
      resize    = 'custom'
    >
      { @renderCategoryFilters() }
      <div className="EmojiSelector-list Dropbox-resizable" ref='list' onScroll={@bound 'onScroll'}>
        <input className='EmojiSelector-searchInput' placeholder='Search' value={query} onChange={@bound 'onSearch'} />
        <List
          numberOfSections={@bound 'numberOfSections'}
          numberOfRowsInSection={@bound 'numberOfRowsInSection'}
          renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
          renderRowAtIndex={@bound 'renderRowAtIndex'}
          sectionClassName='EmojiSelectorSection'
          renderEmptySectionMessageAtIndex={@bound 'renderEmptySectionMessageAtIndex'}
        />
        <div className='clearfix'></div>
      </div>
      <div className="EmojiSelector-footer">
        <span className="EmojiSelector-selectedItemIcon">
          <EmojiIcon emoji={selectedItem or 'cow'} />
        </span>
        <div className="EmojiSelector-selectedItemName">
          {if selectedItem then formatEmojiName selectedItem else 'Choose your emoji!'}
        </div>
        <div className="clearfix" />
      </div>
    </Dropbox>


  helper =

    calculateTotalIndex: (categoryItems, categoryIndex, emojiIndex) ->

      categoryItems = categoryItems.toJS()
      totalIndex    = emojiIndex

      for categoryItem, index in categoryItems when index < categoryIndex
        totalIndex += categoryItem.emojis.length

      return totalIndex


    findCategoryHeader: (category) ->

      return document.querySelector ".EmojiSelectorCategory-#{kd.utils.slugify category}"


    findFilterTab: (className) ->

      return document.querySelector ".categoryFilterTab.#{className}"


    findFilterTabByCategory: (category) ->

      return helper.findFilterTab kd.utils.slugify category

