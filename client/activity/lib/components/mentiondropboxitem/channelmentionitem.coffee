kd                    = require 'kd'
React                 = require 'kd-react'
immutable             = require 'immutable'
classnames            = require 'classnames'
DropboxItem           = require 'activity/components/dropboxitem'
renderHighlightedText = require 'activity/util/renderHighlightedText'

module.exports = class ChannelMentionItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0
    query      : ''


  renderNames: ->

    { item, query } = @props
    names = item.get('names')

    if names.size > 1
      secondaryNames = names.skip(1)
      secondaryItems = secondaryNames.map (name, index) ->
        name = renderHighlightedText name, query, { isBeginningMatch : yes }
        <span>
          @{ name }{ if index is secondaryNames.size - 1 then '' else ', ' }
        </span>

    <span>
      @{ names.first() }
      { if secondaryItems then <span> [{ secondaryItems }]</span> }
    </span>


  renderDescription: ->

    { item }    = @props
    description = item.get 'description'

    return  unless description

    <span className='MentionDropboxItem-secondaryText'>({description})</span>


  render: ->

    <DropboxItem {...@props} className="DropboxItem-singleLine DropboxItem-separated MentionDropboxItem">
      <div className='MentionDropboxItem-names'>
        { @renderNames() }
        { @renderDescription() }
      </div>
    </DropboxItem>

