$                    = require 'jquery'
kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
classnames           = require 'classnames'
immutable            = require 'immutable'
EmojiIcon            = require 'activity/components/emojiicon'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class EmojiSelectBoxTabs extends React.Component

  onTabChange: (tabIndex) -> @props.onTabChange? tabIndex


  render: ->

    { tabs, tabIndex } = @props

    components = tabs.map (item, index) =>
      category     = item.get 'category'
      iconEmoji    = item.get 'iconEmoji'
      tabClassName = classnames
        'EmojiSelectBox-categoryTab' : yes
        'activeTab'                 : index is tabIndex

      <span className={tabClassName} title={category} onClick={@lazyBound 'onTabChange', index} key={category}>
        <span className='emoji-wrapper'>
          <EmojiIcon emoji={iconEmoji} showTooltip=no />
        </span>
      </span>

    <div className='EmojiSelectBox-categoryTabs' ref='tabs'>
      { components }
    </div>


EmojiSelectBoxTabs.include [ImmutableRenderMixin]

