$                     = require 'jquery'
kd                    = require 'kd'
React                 = require 'kd-react'
ReactDOM              = require 'react-dom'
classnames            = require 'classnames'
immutable             = require 'immutable'
ChatInputFlux         = require 'activity/flux/chatinput'
Dropbox               = require 'activity/components/dropbox/portaldropbox'
EmojiIcon             = require 'activity/components/emojiicon'
ScrollableList        = require './scrollablelist'
Tabs                  = require './tabs'
formatEmojiName       = require 'activity/util/formatEmojiName'
getEmojiSynonyms      = require 'activity/util/getEmojiSynonyms'
ImmutableRenderMixin  = require 'react-immutable-render-mixin'


module.exports = class EmojiSelector extends React.Component

  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : ''
    query        : ''
    tabs         : immutable.List()
    tabIndex     : -1


  componentDidUpdate: (prevProps, prevState) ->

    { visible, query } = @props
    isBecomeVisible    = visible and not prevProps.visible

    @refs.list.ready()  if isBecomeVisible


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


  onTabChange: (tabIndex) ->

    { stateId } = @props

    ChatInputFlux.actions.emoji.unsetSelectorQuery stateId
    ChatInputFlux.actions.emoji.setSelectorTabIndex stateId, tabIndex


  close: ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setSelectorVisibility stateId, no


  onSearch: (value) ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setSelectorQuery stateId, value


  renderSelectedItemName: ->

    { selectedItem } = @props

    unless selectedItem
      return <div className='EmojiSelector-noSelectedItem'>Choose your emoji!</div>

    synonyms = getEmojiSynonyms(selectedItem) ? [ selectedItem ]
    synonyms = synonyms.map (emoji) -> formatEmojiName emoji
    synonyms = synonyms.join '  '

    <div>
      <div className='EmojiSelector-selectedItemMainName'>{selectedItem}</div>
      <div className='EmojiSelector-selectedItemSynonyms'>{synonyms}</div>
    </div>


  render: ->

    { items, query, visible, selectedItem, tabs, tabIndex } = @props

    <Dropbox
      className = 'EmojiSelector'
      visible   = { visible }
      onClose   = { @bound 'close' }
      type      = 'dropup'
      right     = 0
      ref       = 'dropbox'
      resize    = 'custom'
    >
      <Tabs tabs={tabs} tabIndex={tabIndex} onTabChange={@bound 'onTabChange'} />
      <ScrollableList
        items            = { items }
        query            = { query }
        sectionIndex     = { tabIndex }
        onItemSelected   = { @bound 'onItemSelected' }
        onItemUnselected = { @bound 'onItemUnselected' }
        onItemConfirmed  = { @bound 'onItemConfirmed' }
        onSectionChange  = { @bound 'onTabChange' }
        onSearch         = { @bound 'onSearch' }
        ref              = 'list'
      />
      <div className="EmojiSelector-footer">
        <span className="EmojiSelector-selectedItemIcon">
          <EmojiIcon emoji={selectedItem or 'cow'} />
        </span>
        <div className="EmojiSelector-selectedItemName">
          { @renderSelectedItemName() }
        </div>
        <div className="clearfix" />
      </div>
    </Dropbox>


EmojiSelector.include [ImmutableRenderMixin]

