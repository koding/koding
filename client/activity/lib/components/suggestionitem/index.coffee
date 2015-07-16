kd                    = require 'kd'
immutable             = require 'immutable'
React                 = require 'kd-react'
Avatar                = require 'app/components/profile/avatar'
SuggestionMessageBody = require 'activity/components/suggestionmessagebody'
ProfileText           = require 'app/components/profile/profiletext'
ProfileLinkContainer  = require 'app/components/profile/profilelinkcontainer'
formatPlural = kd.utils.formatPlural
groupifyLink = require 'app/util/groupifyLink'

module.exports = class SuggestionItem extends React.Component

  handleClick: ->

    { router } = kd.singletons
    slug       = @props.suggestion.get('slug')

    router.handleRoute groupifyLink "/Activity/Post/#{slug}"


  render: ->

    { suggestion }  = @props
    message         = suggestion.get 'message'
    highlightResult = suggestion.get 'highlightResult'

    { makeAvatar, makeProfileLink, makeInfoText } = helper

    <div className="ActivitySuggestionItem" onClick={@bound 'handleClick'}>
      <div className="ActivitySuggestionItem-authorAvatar">
        {makeAvatar message.get('account')}
      </div>
      <div className="ActivitySuggestionItem-messageBody">
        <SuggestionMessageBody source={highlightResult.getIn(['body', 'value'])} />
      </div>
      <div>
        <span className="ActivitySuggestionItem-info ActivitySuggestionItem-profileLink">
          by {makeProfileLink message.get('account')}
        </span>
        <span className="ActivitySuggestionItem-info">
          {makeInfoText message.getIn(['interactions', 'like', 'actorsCount']), 'Like'}
        </span>
        <span className="ActivitySuggestionItem-info">
          {makeInfoText message.get('repliesCount'), 'Comment'}
        </span>
      </div>
    </div>


  #
  # HELPER METHODS
  #
  helper =

    makeProfileLink: (account) ->

      <ProfileLinkContainer origin={account.toJS()}>
        <ProfileText />
      </ProfileLinkContainer>


    makeAvatar: (account) ->

      <ProfileLinkContainer origin={account.toJS()} >
        <Avatar width={20} height={20} />
      </ProfileLinkContainer>


    makeInfoText: (count, noun) -> formatPlural count, noun
