kd = require 'kd'
React = require 'app/react'
Toggle = require 'app/components/common/toggle'
ConfirmModal = require 'lab/ConfirmModal'
classnames = require 'classnames'


module.exports = class GitHubView extends React.Component

  render: ->

    { enabled, applicationId, applicationSecret, scope, isSaving, err
      onInputChange, onSave, onToggleChange, isConfirmModalOpen
      onRemoveCancel, onRemoveSuccess, isRemoving, callbackUrl } = @props

    <div className='HomeAppView--sectionWrapper'>

      <ConfirmModal
        isOpen={isConfirmModalOpen}
        title="Remove GitHub Integration"
        message="Are you sure you want to remove GitHub integration? It will logout all team members who are logged in using this integration."
        confirmTitle={if isRemoving then 'REMOVING...' else 'REMOVE'}
        cancelTitle="CANCEL"
        onCancel={onRemoveCancel}
        onConfirm={onRemoveSuccess} />

      <Toggle
        checked={enabled}
        className='HomeApp-ApiToken--swicth-toggle'
        callback={onToggleChange} />

      <strong>GitHub Integration</strong>
      <div>Koding & GitHub for continous development</div>
      <span className="separator" />

      <GitHubForm
        err={err}
        enabled={enabled}
        callbackUrl={callbackUrl}
        applicationId={applicationId}
        applicationSecret={applicationSecret}
        scope={scope}
        onInputChange={onInputChange} />

      {<SaveButton isSaving={isSaving} callback={onSave} />  if enabled}
      <GuideButton />
    </div>


GitHubForm = ({ err, enabled, applicationId, applicationSecret, scope, onInputChange, callbackUrl }) ->

  return <span />  unless enabled

  if err
  then err = _.assign {}, err, err.error
  else err = { fields: [] }

  <div>
    <cite className='warning'>
      Register a new OAuth application on GitHub by using this URL as authorization callback URL
      <code className='HomeAppView--code'>{callbackUrl}</code>
      and provide generated <code className='HomeAppView--code'>clientId</code> and
      <code className='HomeAppView--code'>clientSecret</code> here. And below you can define
      comma seperated<code className='HomeAppView--code'>scopes</code> you are going to ask from your
      team members. Get details about scopes from GitHub <a href='https://developer.github.com/v3/oauth/#scopes' target='_blank'>documentation</a>.
    </cite>

    <span className="separator" />

    <fieldset>
      {<ErrorMessage message={err.message} />  if err.fields.length}
      <label>Client ID</label>
      <InputArea error={'applicationId' in err?.fields} value={applicationId} callback={onInputChange 'applicationId'} />
      <label>Client Secret</label>
      <InputArea error={'applicationSecret' in err?.fields} value={applicationSecret} callback={onInputChange 'applicationSecret'} />
      <label>Requested Scopes</label>
      <InputArea error={'scope' in err?.fields} value={scope} callback={onInputChange 'scope'} />
    </fieldset>
  </div>


ErrorMessage = ({ message }) ->

  <div className="ErrorMessage">{message}</div>


InputArea = ({ value, callback, error }) ->

  className = classnames [
    'kdinput'
    'text'
    error and 'hasError'
  ]

  <input type="text"
    className={className}
    value={value}
    onChange={callback}/>


SaveButton = ({ isSaving, callback }) ->

  className ="custom-link-view HomeAppView--button primary fr"

  <a className={className} href="#" onClick={callback}>
    <span className="title">
      { if isSaving then 'SAVING...' else 'SAVE' }
    </span>
  </a>


GuideButton = ->

  className = "custom-link-view HomeAppView--button"

  # this might need to change
  href = "https://www.koding.com/docs/github"

  <a className={className} href={href}>
    <span className="title">VIEW GUIDE</span>
  </a>
