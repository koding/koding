kd    = require 'kd'
React = require 'app/react'
timeago = require 'timeago'
ContentModal = require 'app/components/contentModal'
TeamFlux = require 'app/flux/teams'
showError = require 'app/util/showError'
remote = require 'app/remote'
copyToClipboard = require 'app/util/copyToClipboard'

module.exports = class ApiToken extends React.Component

  constructor: (props) ->

    super props

  copyApiToken: ->

    copyToClipboard @refs.token

  deleteApiToken: ->

    modal = new ContentModal
      title : 'Are you sure?'
      overlay : yes
      cssClass : 'content-modal'
      content : '<h2>Do you really want to remove this API token?</h2>'
      buttons :
        Cancel :
          title : 'Cancel'
          cssClass  : 'solid medium'
          callback  : -> modal.destroy()
        Yes :
          title : 'Yes'
          cssClass  : 'solid medium'
          callback  : =>
            apiToken = remote.revive @props.apiToken.toJS()
            apiToken.remove (err) =>
              return showError err  if err
              TeamFlux.actions.deleteApiToken @props.apiToken.get '_id'
              modal.destroy()

  render: ->

    { code, createdAt, username } = @props.apiToken.toJS()

    _code = code
    _code = '********-****-****-****-************'  if code is '*'

    createdAt = timeago createdAt
    className = 'HomeApp-ApiToken--api-wrapper'
    className = "#{className}--disabled"  unless @props.toggleState

    <div>
      <div className={className}>
        <div ref='token' className='HomeApp-ApiToken--api-token'>
          {_code}
        </div>
        <div className='HomeApp-ApiToken--api-token-detail'>
          {createdAt} by {username}
        </div>
      </div>
      <CopyButton code={code} callback={@bound 'copyApiToken'} />
      <DeleteButton callback={@bound 'deleteApiToken'}/>
    </div>


DeleteButton = ({ callback }) ->
  <a className='HomeApp-ApiToken--custom-link-view delete-api-token fr' onClick={callback}>DELETE</a>

CopyButton = ({ code, callback }) ->
  return null  if code is '*'
  <a className='HomeApp-ApiToken--custom-link-view copy-api-token' onClick={callback}>COPY</a>
