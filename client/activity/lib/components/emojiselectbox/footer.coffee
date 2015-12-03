kd                    = require 'kd'
React                 = require 'kd-react'
ReactDOM              = require 'react-dom'
EmojiIcon             = require 'activity/components/emojiicon'
formatEmojiName       = require 'activity/util/formatEmojiName'
getEmojiSynonyms      = require 'activity/util/getEmojiSynonyms'
ImmutableRenderMixin  = require 'react-immutable-render-mixin'


module.exports = class EmojiSelectBoxFooter extends React.Component

  @defaultProps =
    selectedItem : ''


  renderNoItemName: ->

    { selectedItem } = @props
    return  if selectedItem

    <div className='EmojiSelectBox-noSelectedItem'>Choose your emoji!</div>


  renderSelectedItemName: ->

    { selectedItem } = @props
    return  unless selectedItem

    synonyms = getEmojiSynonyms(selectedItem) ? [ selectedItem ]
    synonyms = synonyms.map (emoji) -> formatEmojiName emoji
    synonyms = synonyms.join ' '

    <div>
      <div className='EmojiSelectBox-selectedItemMainName'>{selectedItem}</div>
      <div className='EmojiSelectBox-selectedItemSynonyms'>{synonyms}</div>
    </div>


  render: ->

    { selectedItem } = @props

    <div className="EmojiSelectBox-footer">
      <span className="EmojiSelectBox-selectedItemIcon">
        <EmojiIcon emoji={selectedItem or 'cow'} />
      </span>
      <div className="EmojiSelectBox-selectedItemName">
        { @renderNoItemName() }
        { @renderSelectedItemName() }
      </div>
      <div className="clearfix" />
    </div>

EmojiSelectBoxFooter.include [ImmutableRenderMixin]

