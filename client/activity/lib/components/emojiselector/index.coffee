$                     = require 'jquery'
kd                    = require 'kd'
React                 = require 'kd-react'
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


  updatePosition: (inputDimensions) -> @refs.dropbox.setInputDimensions inputDimensions


  onItemSelected: (index) ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setCommonListSelectedIndex stateId, index


  onItemConfirmed: ->

    { selectedItem } = @props
    @props.onItemConfirmed? formatEmojiName selectedItem
    @close()


  close: ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setCommonListVisibility stateId, no


  scrollToCategory: (category) ->

    list = React.findDOMNode @refs.list
    return list.scrollTop = 0  unless category

    header    = $ ".EmojiSelectorCategory-#{kd.utils.slugify category}"
    headerTop = header.position().top

    list.scrollTop += headerTop


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


  renderCategoryFilters: ->

    { items } = @props

    filters = items.map (item) =>
      iconClassName = "emoji-sprite emoji-#{item.get('emojis').get(0)}"
      category      = item.get 'category'

      <span className='categoryFilterTab' title={category} onClick={@lazyBound 'scrollToCategory', category}>
        <span className='emoji-wrapper'>
          <span className={iconClassName}></span>
        </span>
      </span>

    <div className='EmojiSelector-categoryFilters'>
      <span className='categoryFilterTab' title='All' onClick={@lazyBound 'scrollToCategory', ''}>
        <span className='emoji-wrapper'>
          <span className='emoji-sprite emoji-clock3'></span>
        </span>
      </span>
      { filters }
    </div>


  render: ->

    { visible, selectedItem } = @props

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
      <div className="EmojiSelector-list Dropbox-resizable" ref='list'>
        <List
          numberOfSections={@bound 'numberOfSections'}
          numberOfRowsInSection={@bound 'numberOfRowsInSection'}
          renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
          renderRowAtIndex={@bound 'renderRowAtIndex'}
          sectionClassName='EmojiSelectorSection'
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

