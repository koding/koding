kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
DropboxItem          = require 'activity/components/dropboxitem'
Avatar               = require 'app/components/profile/avatar'
highlightQueryInWord = require 'activity/util/highlightQueryInWord'
findNameByQuery      = require 'activity/util/findNameByQuery'

module.exports = class UserMentionItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0
    query      : ''


  render: ->

    { item, query } = @props
    account         = item.toJS()

    <DropboxItem {...@props} className="DropboxItem-singleLine DropboxItem-separated MentionDropboxItem">
      <Avatar width='25' height='25' account={account} />
      <div className='MentionDropboxItem-names'>
        <span className='MentionDropboxItem-nickname'>
          { account.profile.nickname }
        </span>
        { helper.renderFullName account, query }
      </div>
      <div className='clearfix' />
    </DropboxItem>


  helper =

    renderFullName: (account, query) ->

      { firstName, lastName, nickname } = account.profile

      fullNameClass = classnames
        'MentionDropboxItem-secondaryText' : yes
        'hidden'                           : not (firstName and lastName)

      # Do not highlight query in any name, if it's found in nickname.
      # Highlighting in first and last name is intended to show
      # why mention is selected via search when it's found not by nickname
      # but by first or last names
      shouldHighlight = findNameByQuery([ nickname, firstName, lastName ], query) isnt nickname

      <span className={fullNameClass}>
        { helper.renderFullNameItem "#{firstName} ", shouldHighlight, query }
        { helper.renderFullNameItem lastName, shouldHighlight, query }
      </span>


    renderFullNameItem: (text, shouldHighlight, query) ->

      if shouldHighlight
      then highlightQueryInWord text, query
      else text

