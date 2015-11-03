kd                     = require 'kd'
React                  = require 'kd-react'
immutable              = require 'immutable'
classnames             = require 'classnames'
Dropbox                = require 'activity/components/dropbox/portaldropbox'
UserMentionItem        = require 'activity/components/mentiondropboxitem/usermentionitem'
ChannelMentionItem     = require 'activity/components/mentiondropboxitem/channelmentionitem'
DropboxWrapperMixin    = require 'activity/components/dropbox/dropboxwrappermixin'
ChatInputFlux          = require 'activity/flux/chatinput'
ImmutableRenderMixin   = require 'react-immutable-render-mixin'
isWithinCodeBlock      = require 'app/util/isWithinCodeBlock'
findNameByQuery        = require 'activity/util/findNameByQuery'


module.exports = class MentionDropbox extends React.Component

  @include [ImmutableRenderMixin, DropboxWrapperMixin]


  @defaultProps =
    userMentions    : immutable.List()
    channelMentions : immutable.List()
    visible         : no
    selectedIndex   : 0
    selectedItem    : null


  isActive: ->

    { userMentions, channelMentions, visible } = @props
    return (userMentions.size + channelMentions.size) > 0 and visible


  hasSingleItem: ->

    { userMentions, channelMentions, visible } = @props
    return (userMentions.size + channelMentions.size) is 1


  hasUsers: -> @props.userMentions.size > 0


  formatSelectedValue: ->

    { selectedItem, query } = @props
    names = selectedItem.get('names')

    if names
      name = findNameByQuery(names.toJS(), query) ? names.first()
    else
      name = selectedItem.getIn ['profile', 'nickname']

    return "@#{name}"


  getItemKey: (item) ->

    names = item.get('names')

    if names then names.first() else item.get '_id'


  close: ->

    { stateId } = @props
    ChatInputFlux.actions.mention.setVisibility stateId, no


  moveToNextPosition: (keyInfo) ->

    if keyInfo.isRightArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.mention.moveToNextIndex stateId

    return yes


  moveToPrevPosition: (keyInfo) ->

    if keyInfo.isLeftArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.mention.moveToPrevIndex stateId

    return yes


  checkTextForQuery: (textData) ->

    { currentWord, value, position } = textData
    return no  unless currentWord
    return no  if isWithinCodeBlock value, position

    matchResult = currentWord.match /^@(.*)/
    return no  unless matchResult

    query = matchResult[1]
    { stateId } = @props
    ChatInputFlux.actions.mention.setQuery stateId, query
    ChatInputFlux.actions.mention.setVisibility stateId, yes

    return yes


  onItemSelected: (index) ->

    { stateId } = @props
    ChatInputFlux.actions.mention.setSelectedIndex stateId, index


  renderUserMentions: ->

    { userMentions, selectedIndex, query } = @props

    userMentions.map (item, index) =>
      isSelected = index is selectedIndex

      <UserMentionItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
        query       = { query }
      />


  renderChannelMentionsHeader: ->

    { channelMentions } = @props
    return  if channelMentions.size is 0 or not @hasUsers()

    <div className='Dropbox-header MentionDropbox-groupsHeader DropboxItem-separated'>
      Groups
    </div>


  renderChannelMentions: ->

    { userMentions, channelMentions, selectedIndex, query } = @props

    channelMentions.map (item, index) =>
      index += userMentions.size
      isSelected = index is selectedIndex

      <ChannelMentionItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
        query       = { query }
      />


  render: ->

    { userMentions } = @props

    title = if @hasUsers() then 'People' else 'Groups'

    <Dropbox
      className = 'MentionDropbox'
      visible   = { @isActive() }
      onClose   = { @bound 'close' }
      type      = 'dropup'
      title     = { title }
      ref       = 'dropbox'
    >
      { @renderUserMentions() }
      { @renderChannelMentionsHeader() }
      { @renderChannelMentions() }
    </Dropbox>

