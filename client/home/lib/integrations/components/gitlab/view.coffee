kd = require 'kd'
React = require 'app/react'
Toggle = require 'app/components/common/toggle'
ConfirmModal = require 'lab/ConfirmModal'
classnames = require 'classnames'


module.exports = class GitLabView extends React.Component

  render: ->

    { enabled, url, applicationId, applicationSecret, isSaving, err
      onInputChange, onSave, onToggleChange, isConfirmModalOpen
      onRemoveCancel, onRemoveSuccess, isRemoving, callbackUrl } = @props

    <div className='HomeAppView--sectionWrapper'>

      <ConfirmModal
        isOpen={isConfirmModalOpen}
        title="Remove GitLab Integration"
        message="Are you sure you want to remove GitLab integration? It will logout all team members who are logged in using this integration."
        confirmTitle={if isRemoving then 'REMOVING...' else 'REMOVE'}
        cancelTitle="CANCEL"
        onCancel={onRemoveCancel}
        onConfirm={onRemoveSuccess} />

      <Toggle
        checked={enabled}
        className='HomeApp-ApiToken--swicth-toggle'
        callback={onToggleChange} />

      <strong>GitLab Integration</strong>
      <div>Koding & GitLab for continous development</div>
      <span className="separator" />

      <GitLabForm
        url={url}
        err={err}
        enabled={enabled}
        callbackUrl={callbackUrl}
        applicationId={applicationId}
        applicationSecret={applicationSecret}
        onInputChange={onInputChange} />

      {<SaveButton isSaving={isSaving} callback={onSave} />  if enabled}
      <GuideButton />
    </div>


GitLabForm = ({ err, url, enabled, applicationId, applicationSecret, onInputChange, callbackUrl }) ->

  return <span />  unless enabled

  if err
  then err = _.assign {}, err, err.error
  else err = { fields: [] }

  <div>
    <cite className='warning'>
      Create a new application on your GitLab instance by using this address as endpoint:
      <code className='HomeAppView--code'>{callbackUrl}</code>
      and provide generated <code className='HomeAppView--code'>applicationId</code> and
      <code className='HomeAppView--code'>applicationSecret</code> here with the public
      <code className='HomeAppView--code'>url</code> of your GitLab instance.
    </cite>

    <span className="separator" />

    <fieldset>
      {<ErrorMessage message={err.message} />  if err.fields.length}
      <label>GitLab URL</label>
      <InputArea error={'url' in err?.fields} value={url} callback={onInputChange 'url'} />
      <label>Application ID</label>
      <InputArea error={'applicationId' in err?.fields} value={applicationId} callback={onInputChange 'applicationId'} />
      <label>Application Secret</label>
      <InputArea error={'applicationSecret' in err?.fields} value={applicationSecret} callback={onInputChange 'applicationSecret'} />
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
  href = "https://www.koding.com/docs/gitlab"

  <a className={className} href={href}>
    <span className="title">VIEW GUIDE</span>
  </a>
