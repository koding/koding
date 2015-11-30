$                    = require 'jquery'
kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
classnames           = require 'classnames'
immutable            = require 'immutable'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class EmojiSelectorTabs extends React.Component

  onTabChange: (tabIndex) -> @props.onTabChange? tabIndex


  render: ->

    { tabs, tabIndex } = @props

    components = tabs.map (item, index) =>
      tabClassName  = classnames
        'EmojiSelector-categoryTab' : yes
        'activeTab'                 : index is tabIndex
      iconClassName = "emoji-sprite emoji-#{item.get('iconEmoji')}"
      category      = item.get 'category'

      <span className={tabClassName} title={category.capitalize()} onClick={@lazyBound 'onTabChange', index} key={category}>
        <span className='emoji-wrapper'>
          <span className={iconClassName}></span>
        </span>
      </span>

    allTabClassName = classnames
      'EmojiSelector-categoryTab' : yes
      'activeTab'                 : tabIndex is -1
    <div className='EmojiSelector-categoryTabs' ref='tabs'>
      <span className={allTabClassName} title='All' onClick={@lazyBound 'onTabChange', -1}>
        <span className='emoji-wrapper'>
          <span className='emoji-sprite emoji-clock3'></span>
        </span>
      </span>
      { components }
    </div>


EmojiSelectorTabs.include [ImmutableRenderMixin]

