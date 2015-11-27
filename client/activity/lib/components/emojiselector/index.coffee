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
ListWithTabsMixin     = require './listwithtabsmixin'


module.exports = class EmojiSelector extends React.Component

  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : ''
    query        : ''
    tabIndex     : -1


  componentDidUpdate: (prevProps, prevState) ->

    { visible, query } = @props
    isBecomeVisible    = visible and not prevProps.visible

    @calculateSectionPositions()  if isBecomeVisible


  updatePosition: (inputDimensions) -> @refs.dropbox.setInputDimensions inputDimensions


  onItemSelected: (index) ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setSelectorSelectedIndex stateId, index


  onItemConfirmed: ->

    { selectedItem } = @props
    @props.onItemConfirmed? formatEmojiName selectedItem
    @close()


  isTabHighlightingEnabled: -> not @props.query


  setTabIndex: (tabIndex) ->

    { stateId } = @props

    ChatInputFlux.actions.emoji.unsetSelectorQuery stateId
    ChatInputFlux.actions.emoji.setSelectorTabIndex stateId, tabIndex


  close: ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setSelectorVisibility stateId, no


  onSearch: (event) ->

    { value }   = event.target
    { stateId } = @props

    ChatInputFlux.actions.emoji.setSelectorQuery stateId, value


  numberOfSections: ->

    return @props.items.size


  numberOfRowsInSection: (sectionIndex) ->

    return @props.items.get(sectionIndex).get('emojis').size


  sectionId: (sectionIndex) ->

    category = @props.items.get(sectionIndex).get 'category'
    return "EmojiSelectorCategory-#{kd.utils.slugify category}"


  renderSectionHeaderAtIndex: (sectionIndex) ->

    category = @props.items.get(sectionIndex).get 'category'
    <header className='EmojiSelector-categorySectionHeader'>{category}</header>


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    { items, selectedItem } = @props

    emojis     = items.get(sectionIndex).get('emojis')
    item       = emojis.get rowIndex
    isSelected = selectedItem is item

    result = [<EmojiSelectorItem
      item         = { item }
      index        = { helper.calculateTotalIndex items, sectionIndex, rowIndex }
      isSelected   = { isSelected }
      onSelected   = { @bound 'onItemSelected' }
      onConfirmed  = { @bound 'onItemConfirmed' }
      key          = { item }
    />]
    result.push <div className='clearfix' key='clearfix' />  if rowIndex is emojis.size - 1

    return result

  renderEmptySectionMessageAtIndex: (sectionIndex) ->

    <div className='EmojiSelector-emptyCategory'>No emoji found</div>


  renderCategoryTabs: ->

    { tabs, tabIndex } = @props

    components = tabs.map (item, index) =>
      tabClassName  = classnames
        'EmojiSelector-categoryTab' : yes
        'activeTab'                 : index is tabIndex
      iconClassName = "emoji-sprite emoji-#{item.get('iconEmoji')}"
      category      = item.get 'category'

      <span className={tabClassName} title={category} onClick={@lazyBound 'setTabIndex', index} key={category}>
        <span className='emoji-wrapper'>
          <span className={iconClassName}></span>
        </span>
      </span>

    allTabClassName = classnames
      'EmojiSelector-categoryTab' : yes
      'activeTab'                 : tabIndex is -1
    <div className='EmojiSelector-categoryTabs' ref='tabs'>
      <span className={allTabClassName} title='All' onClick={@lazyBound 'setTabIndex', -1}>
        <span className='emoji-wrapper'>
          <span className='emoji-sprite emoji-clock3'></span>
        </span>
      </span>
      { components }
    </div>


  renderFixedCategoryHeader: ->

    { items, tabIndex, query } = @props

    index    = if query then 0 else tabIndex
    category = items.get(index).get 'category'

    <header className='EmojiSelector-categorySectionHeader fixedHeader hidden' ref='fixedHeader'>{category}</header>


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
      { @renderCategoryTabs() }
      {@renderFixedCategoryHeader()}
      <div className="EmojiSelector-list Dropbox-resizable" ref='list' onScroll={@bound 'onScroll'}>
        <input className='EmojiSelector-searchInput' placeholder='Search' value={query} onChange={@bound 'onSearch'} />
        <List
          numberOfSections={@bound 'numberOfSections'}
          numberOfRowsInSection={@bound 'numberOfRowsInSection'}
          renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
          renderRowAtIndex={@bound 'renderRowAtIndex'}
          sectionClassName='EmojiSelector-categorySection'
          sectionId={@bound 'sectionId'}
          renderEmptySectionMessageAtIndex={@bound 'renderEmptySectionMessageAtIndex'}
        />
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


React.Component.include.call EmojiSelector, [ImmutableRenderMixin, ListWithTabsMixin]

