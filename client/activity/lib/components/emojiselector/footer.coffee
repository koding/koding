kd                    = require 'kd'
React                 = require 'kd-react'
ReactDOM              = require 'react-dom'
EmojiIcon             = require 'activity/components/emojiicon'
formatEmojiName       = require 'activity/util/formatEmojiName'
getEmojiSynonyms      = require 'activity/util/getEmojiSynonyms'
ImmutableRenderMixin  = require 'react-immutable-render-mixin'


module.exports = class EmojiSelectorFooter extends React.Component

  @defaultProps =
    selectedItem : ''


  renderNoItemName: ->

    { selectedItem } = @props
    return  if selectedItem

    <div className='EmojiSelector-noSelectedItem'>Choose your emoji!</div>


  renderSelectedItemName: ->

    { selectedItem } = @props
    return  unless selectedItem

    synonyms = getEmojiSynonyms(selectedItem) ? [ selectedItem ]
    synonyms = synonyms.map (emoji) -> formatEmojiName emoji
    synonyms = synonyms.join ' '

    <div>
      <div className='EmojiSelector-selectedItemMainName'>{selectedItem}</div>
      <div className='EmojiSelector-selectedItemSynonyms'>{synonyms}</div>
    </div>


  render: ->

    { selectedItem } = @props

    <div className="EmojiSelector-footer">
      <span className="EmojiSelector-selectedItemIcon">
        <EmojiIcon emoji={selectedItem or 'cow'} />
      </span>
      <div className="EmojiSelector-selectedItemName">
        { @renderNoItemName() }
        { @renderSelectedItemName() }
      </div>
      <div className="clearfix" />
    </div>

EmojiSelectorFooter.include [ImmutableRenderMixin]

