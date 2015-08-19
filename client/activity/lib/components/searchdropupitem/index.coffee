kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
formatPlural         = kd.utils.formatPlural
DropupItem           = require 'activity/components/dropupitem'
SearchItemBody       = require 'activity/components/searchitembody'
ProfileText          = require 'app/components/profile/profiletext'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'


module.exports = class SearchDropupItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0


  render: ->

    { item }    = @props
    message         = item.get 'message'
    highlightResult = item.get 'highlightResult'
    messageBody     = highlightResult?.getIn(['body', 'value']) ? message.get('body')

    { renderProfileLink, renderLikesCount, renderCommentsCount } = helper

    <DropupItem {...@props} className="SearchDropupItem">
      <SearchItemBody source={messageBody} />
      <div>
        <span className="SearchDropupItem-info SearchDropItem-profileLink">
          by { renderProfileLink message }
        </span>
        <span className="SearchDropupItem-info">
          { renderLikesCount message }
        </span>
        <span className="SearchDropupItem-info">
          { renderCommentsCount message }
        </span>
      </div>
    </DropupItem>


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
