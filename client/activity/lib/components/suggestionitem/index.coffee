kd                   = require 'kd'
immutable            = require 'immutable'
React                = require 'kd-react'
Avatar               = require 'app/components/profile/avatar'
SuggestionMessageBody = require 'activity/components/suggestionmessagebody'
ProfileText          = require 'app/components/profile/profiletext'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
formatPlural = kd.utils.formatPlural
groupifyLink = require 'app/util/groupifyLink'

module.exports = class SuggestionItem extends React.Component

  render: ->

    { message, query } = @props
    <div className="ActivitySuggestionItem">
      <div className="ActivitySuggestionItem-authorAvatar">
        {makeAvatar message.account}
      </div>
      <div className="ActivitySuggestionItem-messageBody">
        <SuggestionMessageBody source={message.body} query={query} />
      </div>
      <div>
        <span className="ActivitySuggestionItem-info ActivitySuggestionItem-profileLink">
          by {makeProfileLink message.account}
        </span>
        <span className="ActivitySuggestionItem-info">
          {makeInfoText message.interactions.like.actorsCount, 'Like'}
        </span>
        <span className="ActivitySuggestionItem-info">
          {makeInfoText message.repliesCount, 'Comment'}
        </span>
      </div>
    </div>


makeProfileLink = (account) ->
  <ProfileLinkContainer origin={account}>
    <ProfileText />
  </ProfileLinkContainer>


makeAvatar = (account) ->
  <ProfileLinkContainer origin={account} >
    <Avatar width={20} height={20} />
  </ProfileLinkContainer>


makeInfoText = (count, noun) -> formatPlural count, noun