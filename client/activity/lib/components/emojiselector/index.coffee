kd                    = require 'kd'
React                 = require 'kd-react'
ReactDOM              = require 'react-dom'
immutable             = require 'immutable'
ChatInputFlux         = require 'activity/flux/chatinput'
Dropbox               = require 'activity/components/dropbox/portaldropbox'
ScrollableList        = require './scrollablelist'
Tabs                  = require './tabs'
Footer                = require './footer'
formatEmojiName       = require 'activity/util/formatEmojiName'
ImmutableRenderMixin  = require 'react-immutable-render-mixin'


module.exports = class EmojiSelector extends React.Component

  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : ''
    query        : ''
    tabs         : immutable.List()
    tabIndex     : -1


  updatePosition: (inputDimensions) ->

    @refs.dropbox.setInputDimensions inputDimensions


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


  renderList: ->

    { visible, items, query, tabIndex } = @props

    return  unless visible

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
      { @renderList() }
      <Footer selectedItem={selectedItem} />
    </Dropbox>


EmojiSelector.include [ImmutableRenderMixin]

