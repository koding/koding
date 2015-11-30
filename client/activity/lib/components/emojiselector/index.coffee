$                     = require 'jquery'
kd                    = require 'kd'
React                 = require 'kd-react'
ReactDOM              = require 'react-dom'
classnames            = require 'classnames'
immutable             = require 'immutable'
formatEmojiName       = require 'activity/util/formatEmojiName'
ChatInputFlux         = require 'activity/flux/chatinput'
Dropbox               = require 'activity/components/dropbox/portaldropbox'
EmojiIcon             = require 'activity/components/emojiicon'
List                  = require './list'
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


  onItemUnselected: ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.resetSelectorSelectedIndex stateId


  onItemConfirmed: ->

    { selectedItem } = @props
    @props.onItemConfirmed? formatEmojiName selectedItem
    @close()


  sectionId: (sectionIndex) -> @refs.list.sectionId sectionIndex


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


  renderCategoryTabs: ->

    { tabs, tabIndex } = @props

    components = tabs.map (item, index) =>
      tabClassName  = classnames
        'EmojiSelector-categoryTab' : yes
        'activeTab'                 : index is tabIndex
      iconClassName = "emoji-sprite emoji-#{item.get('iconEmoji')}"
      category      = item.get 'category'

      <span className={tabClassName} title={category.capitalize()} onClick={@lazyBound 'setTabIndex', index} key={category}>
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

    { items, query, visible, selectedItem } = @props

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
      <div className="EmojiSelector-list Dropbox-resizable" ref='scrollable' onScroll={@bound 'onScroll'}>
        <input className='EmojiSelector-searchInput' placeholder='Search' value={query} onChange={@bound 'onSearch'} />
        <List
          items            = { items }
          onItemSelected   = { @bound 'onItemSelected' }
          onItemUnselected = { @bound 'onItemUnselected' }
          onItemConfirmed  = { @bound 'onItemConfirmed' }
          ref              = 'list'
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


EmojiSelector.include [ImmutableRenderMixin, ListWithTabsMixin]

