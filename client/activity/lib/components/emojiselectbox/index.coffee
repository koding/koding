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
EmojiBoxWrapperMixin = require 'activity/components/emojiboxwrapper/mixin'


module.exports = class EmojiSelectBox extends React.Component

  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : ''
    query        : ''
    tabs         : immutable.List()
    tabIndex     : 0


  updatePosition: (inputDimensions) ->

    @refs.dropbox.setInputDimensions inputDimensions


  onItemSelected: (index) ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setSelectBoxSelectedIndex stateId, index


  onItemUnselected: ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.resetSelectBoxSelectedIndex stateId


  onItemConfirmed: ->

    @handleSelectedItemConfirmation()

    { selectedItem } = @props
    @props.onItemConfirmed? formatEmojiName selectedItem
    @close()


  onTabChange: (tabIndex) ->

    { stateId } = @props

    ChatInputFlux.actions.emoji.unsetSelectBoxQuery stateId
    ChatInputFlux.actions.emoji.setSelectBoxTabIndex stateId, tabIndex


  close: ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setSelectBoxVisibility stateId, no


  onSearch: (value) ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setSelectBoxQuery stateId, value


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
      className = 'EmojiSelectBox'
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


EmojiSelectBox.include [ImmutableRenderMixin, EmojiBoxWrapperMixin]

