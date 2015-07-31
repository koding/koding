$               = require 'jquery'
kd              = require 'kd'
React           = require 'kd-react'
classnames      = require 'classnames'
ActivityFlux    = require 'activity/flux'
EmojiDropupItem = require 'activity/components/emojidropupitem'

module.exports = class EmojiDropup extends React.Component

  isVisible: -> @props.emojis?.size > 0


  componentDidMount: ->

    document.addEventListener 'mousedown', @bound 'handleMouseClick'


  componentWillUnmount: ->

    document.removeEventListener 'mousedown', @bound 'handleMouseClick'


  componentDidUpdate: ->

    return  unless @isVisible()

    element = $(React.findDOMNode this.refs.dropup)
    element.css top : -element.outerHeight()


  handleItemSelect: (index) ->

    ActivityFlux.actions.emoji.setFilteredListSelectedIndex index


  handleItemClick: ->

    @props.onItemConfirmed?()


  handleMouseClick: (event) ->

    return  unless @isVisible()

    { target } = event
    element    = React.findDOMNode this
    innerClick = $.contains element, target

    ActivityFlux.actions.emoji.unsetFilteredListQuery()  unless innerClick


  renderList: ->

    { emojis, selectedEmoji } = @props

    emojis.map (emoji, index) =>
      isSelected = emoji is selectedEmoji
      <EmojiDropupItem
        emoji      = { emoji }
        isSelected = { isSelected }
        index      = { index }
        onSelect   = { @bound 'handleItemSelect'}
        onClick    = { @bound 'handleItemClick' }
        key        = { emoji }
      />


  render: ->

    { emojis, emojiQuery } = @props
    className = classnames
      'EmojiDropup-container' : yes
      'hidden'                : not @isVisible()

    <div className={className}>
      <div className="EmojiDropup" ref="dropup">
        <div className="EmojiDropup-header">
          Emojis matching <strong>:{emojiQuery}</strong>
        </div>
        {@renderList()}
        <div className="clearfix" />
      </div>
    </div>