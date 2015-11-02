kd                    = require 'kd'
React                 = require 'kd-react'
immutable             = require 'immutable'
classnames            = require 'classnames'
DropboxItem           = require 'activity/components/dropboxitem'
Avatar                = require 'app/components/profile/avatar'
renderHighlightedText = require 'activity/util/renderHighlightedText'
findNameByQuery       = require 'activity/util/findNameByQuery'

module.exports = class UserDropboxItem extends React.Component

  @defaultProps =
    item       : immutable.Map()
    isSelected : no
    index      : 0
    query      : ''


  render: ->

    { item, query } = @props
    account         = item.toJS()

    <DropboxItem {...@props} className="DropboxItem-singleLine DropboxItem-separated UserDropboxItem">
      <Avatar width='25' height='25' account={account} />
      <div className='UserDropboxItem-names'>
        <span className='UserDropboxItem-nickname'>
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
        'UserDropboxItem-secondaryText' : yes
        'hidden'                        : not (firstName and lastName)

      shouldHighlight = findNameByQuery([ nickname, firstName, lastName ], query) isnt nickname

      <span className={fullNameClass}>
        { helper.renderFullNameItem "#{firstName} ", shouldHighlight, query }
        { helper.renderFullNameItem lastName, shouldHighlight, query }
      </span>


    renderFullNameItem: (text, shouldHighlight, query) ->

      if shouldHighlight
      then renderHighlightedText text, query
      else text

