kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
formatPlural         = kd.utils.formatPlural
formatContent        = require 'app/util/formatReactivityContent'
DropboxItem          = require 'activity/components/dropboxitem'
SearchItemBody       = require 'activity/components/searchitembody'
ProfileText          = require 'app/components/profile/profiletext'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'


module.exports = class SearchDropboxItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0


  render: ->

    { item }        = @props
    message         = item.get 'message'
    highlightResult = item.get 'highlightResult'
    messageBody     = highlightResult?.getIn(['body', 'value']) ? message.get('body')

    { renderProfileLink, renderLikesCount, renderCommentsCount } = helper

    <DropboxItem {...@props} className="DropboxItem-separated SearchDropboxItem">
      <SearchItemBody source={messageBody} contentFormatter={formatContent} />
      <div>
        <span className="SearchDropboxItem-info SearchDropboxItem-profileLink">
          by { renderProfileLink message }
        </span>
        <span className="SearchDropboxItem-info">
          { renderLikesCount message }
        </span>
        <span className="SearchDropboxItem-info">
          { renderCommentsCount message }
        </span>
      </div>
    </DropboxItem>


  helper =

    renderProfileLink: (message) ->

      account = message.get 'account'

      <ProfileLinkContainer origin={account.toJS()}>
        <ProfileText />
      </ProfileLinkContainer>


    renderLikesCount: (message) ->

      likes = message.getIn ['interactions', 'like', 'actorsCount']
      formatPlural likes, 'Like'


    renderCommentsCount: (message) ->

      comments = message.get 'repliesCount'
      formatPlural comments, 'Comment'

