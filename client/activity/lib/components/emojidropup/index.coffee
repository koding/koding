$          = require 'jquery'
kd         = require 'kd'
React      = require 'kd-react'
classnames = require 'classnames'

ActivityFlux    = require 'activity/flux'
EmojiDropupItem = require 'activity/components/emojidropupitem'

module.exports = class EmojiDropup extends React.Component

  componentDidMount: ->

    document.addEventListener 'mousedown', @bound 'handleMouseClick'


  componentWillUnmount: ->

    document.removeEventListener 'mousedown', @bound 'handleMouseClick'


  componentDidUpdate: ->

    element = $(React.findDOMNode this.refs.dropup)
    element.css top : -element.outerHeight()


  handleMouseClick: (event) ->

    { target }  = event
    element     = React.findDOMNode this
    isVisible   = not element.classList.contains 'hidden'
    shouldClear = isVisible and not $.contains element, target

    ActivityFlux.actions.emoji.unsetEmojiQuery()  if shouldClear


  renderList: ->

    { emojis, selectedEmoji } = @props

    emojis.map (emoji, index) ->
      isSelected = emoji is selectedEmoji.get 'emoji'
      <EmojiDropupItem emoji={emoji} isSelected={isSelected} index={index} />


  render: ->

    { emojis, emojiQuery } = @props
    className = classnames
      'EmojiDropup-container' : yes
      'hidden'                : emojis.size is 0

    <div className={className}>
      <div className="EmojiDropup" ref="dropup">
        <div className="EmojiDropup-header">
          Emojis matching <strong>:{emojiQuery}</strong>
        </div>
        {@renderList()}
        <div className="clearfix" />
      </div>
    </div>