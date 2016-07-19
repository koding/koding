kd    = require 'kd'
React = require 'kd-react'
timeago = require 'timeago'
ContentModal = require 'app/components/contentModal'
TeamFlux = require 'app/flux/teams'
showError = require 'app/util/showError'
remote = require('app/remote').getInstance()

module.exports = class ApiToken extends React.Component

  constructor: (props) ->

    super props

  deleteApiToken: ->

    modal = new ContentModal
      title : 'Are you sure?'
      overlay : yes
      cssClass : 'content-modal'
      content : '<h2>Do you really want to remove this API token?</h2>'
      buttons :
        Cancel :
          title : 'Cancel'
          callback  : -> modal.destroy()
        Yes :
          title : 'Yes'
          callback  : =>
              apiToken = remote.revive @props.apiToken.toJS()
              apiToken.remove (err) =>
                return showError err  if err
                TeamFlux.actions.deleteApiToken @props.apiToken.get 'code'
                modal.destroy()



  render: ->

    { code, createdAt, username } = @props.apiToken.toJS()
    createdAt = timeago createdAt

    className = 'HomeApp-ApiToken--api-wrapper'
    className = "#{className}--disabled"  unless @props.toggleState

    <div>
      <div className={className}>
        <div className='HomeApp-ApiToken--api-token'>
          {code}
        </div>
        <div className='HomeApp-ApiToken--api-token-detail'>
          {createdAt} by {username}
        </div>
      </div>
      <DeleteButton callback={@bound 'deleteApiToken'}/>
    </div>


DeleteButton = ({ callback }) ->
  <a className='HomeApp-ApiToken--custom-link-view delete-api-token fr' onClick={callback}>DELETE</a>
