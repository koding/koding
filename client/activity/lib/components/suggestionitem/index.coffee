kd                    = require 'kd'
immutable             = require 'immutable'
React                 = require 'kd-react'
Avatar                = require 'app/components/profile/avatar'
SearchItemBody        = require 'activity/components/searchitembody'
ProfileText           = require 'app/components/profile/profiletext'
ProfileLinkContainer  = require 'app/components/profile/profilelinkcontainer'
formatPlural          = kd.utils.formatPlural
classnames            = require 'classnames'
formatContent         = require 'app/util/formatContent'

module.exports = class SuggestionItem extends React.Component

  handleSelect: ->

    { onSelected, index } = @props
    onSelected? index


  render: ->

    { suggestion, isSelected, onConfirmed }  = @props
    message         = suggestion.get 'message'
    highlightResult = suggestion.get 'highlightResult'
    messageBody     = highlightResult?.getIn(['body', 'value']) ? message.get('body')

    { makeAvatar, makeProfileLink, makeInfoText } = helper

    className = classnames
      'ActivitySuggestionItem'          : yes
      'ActivitySuggestionItem-selected' : isSelected

    <div className={className} onClick={onConfirmed} onMouseEnter={@bound 'handleSelect'}>
      <div className="ActivitySuggestionItem-authorAvatar">
        {makeAvatar message.get('account')}
      </div>
      <div className="ActivitySuggestionItem-messageBody">
        <SearchItemBody source={messageBody} formatContentFn={formatContent} />
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

