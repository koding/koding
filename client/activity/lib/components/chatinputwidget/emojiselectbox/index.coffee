kd                    = require 'kd'
React                 = require 'kd-react'
ReactDOM              = require 'react-dom'
immutable             = require 'immutable'
ChatInputFlux         = require 'activity/flux/chatinput'
PortalDropbox         = require 'activity/components/dropbox/portaldropbox'
ScrollableList        = require './scrollablelist'
Tabs                  = require './tabs'
Footer                = require './footer'
ImmutableRenderMixin  = require 'react-immutable-render-mixin'

module.exports = class EmojiSelectBox extends React.Component

  @propTypes =
    items           : React.PropTypes.instanceOf immutable.List
    visible         : React.PropTypes.bool
    selectedItem    : React.PropTypes.string
    query           : React.PropTypes.string
    tabs            : React.PropTypes.instanceOf immutable.List
    tabIndex        : React.PropTypes.number
    onItemConfirmed : React.PropTypes.func


  @defaultProps =
    items           : immutable.List()
    visible         : no
    selectedItem    : ''
    query           : ''
    tabs            : immutable.List()
    tabIndex        : 0
    onItemConfirmed : kd.noop


  componentDidMount: -> ChatInputFlux.actions.emoji.loadUsageCounts()


  updatePosition: (inputDimensions) ->

    @refs.dropbox.setInputDimensions inputDimensions


  renderList: ->

    { visible, items, query, tabIndex, onItemSelected,
      onItemUnselected, onItemConfirmed, onTabChange, onSearch } = @props

    return  unless visible

    <ScrollableList
      items            = { items }
      query            = { query }
      sectionIndex     = { tabIndex }
      onItemSelected   = { onItemSelected }
      onItemUnselected = { onItemUnselected }
      onItemConfirmed  = { onItemConfirmed }
      onSectionChange  = { onTabChange }
      onSearch         = { onSearch }
      ref              = 'list'
    />


  render: ->

    { items, query, visible, selectedItem, tabs, tabIndex, onClose, onTabChange } = @props

    <PortalDropbox
      className = 'EmojiSelectBox'
      visible   = { visible }
      onClose   = { onClose }
      type      = 'dropup'
      right     = 0
      ref       = 'dropbox'
      resize    = 'custom'
    >
      <Tabs tabs={tabs} tabIndex={tabIndex} onTabChange={onTabChange} />
      { @renderList() }
      <Footer selectedItem={selectedItem} />
    </PortalDropbox>


EmojiSelectBox.include [ImmutableRenderMixin]
