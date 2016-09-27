_ = require 'lodash'
kd = require 'kd'
React = require 'app/react'
View = require './view'
getGroup = require 'app/util/getGroup'


saveGitlabConfig = (options = {}, callback) ->
  options = _.assign {}, options, { provider: 'gitlab' }

  getGroup().setOauth options, callback


module.exports = class GitLabContainer extends React.Component

  constructor: (props) ->

    super props

    @state = @makeInitialState()


  makeInitialState: ->
    return {
      enabled: no
      url: ''
      applicationId: ''
      applicationSecret: ''
      isConfirmModalOpen: no
      isSaving: no
      isRemoving: no
      err: null
    }


  componentDidMount: ->

    return  unless getGroup().config?.gitlab?

    { gitlab } = getGroup().config

    @setState
      enabled: gitlab.enabled
      url: gitlab.url
      applicationId: gitlab.applicationId


  onInputChange: (field) -> (event) =>

    state = _.assign {}, @state
    state[field] = event.target.value

    @setState state


  onToggleChange: (enabled) ->

    @setState { enabled }

    # just show form if it's going from disabled to enabled.
    return  if enabled

    wasEnabled = getGroup().config?.gitlab?.enabled

    return  if not wasEnabled

    @setState { isConfirmModalOpen: yes }


  onRemoveCancel: ->

    state = _.assign {}, @state,
      enabled: getGroup().config.gitlab.enabled
      isConfirmModalOpen: no

    @setState state


  onRemoveSuccess: ->
    @setState { isRemoving: yes, enabled: false }

    options = _.pick @state, 'url', 'applicationId', 'applicationSecret'
    options.enabled = no

    saveGitlabConfig options, (err) =>
      if err
      then @setState { enabled: yes }
      else @setState @makeInitialState()


  onSave: ->

    @setState { isSaving: yes }, =>

      # get data from the form/state
      options = _.pick @state, 'url', 'applicationId', 'applicationSecret'

      # mark it as `enabled` to make sure.
      options.enabled = yes

      # save it to the config
      saveGitlabConfig options, (err, config) =>

        newState = {}
        newState.err = err  if err
        newState = _.pick options, 'url', 'applicationId'
        newState.applicationSecret = ''
        newState.err = err
        newState.isSaving = no

        @setState newState


  render: ->

    { enabled, url, applicationId, isRemoving, err
      isSaving, applicationSecret, isConfirmModalOpen } = @state

    <View
      enabled={enabled}
      url={url}
      err={err}
      applicationId={applicationId}
      applicationSecret={applicationSecret}
      isConfirmModalOpen={isConfirmModalOpen}
      isRemoving={isRemoving}
      isSaving={isSaving}
      onToggleChange={@bound 'onToggleChange'}
      onRemoveSuccess={@bound 'onRemoveSuccess'}
      onRemoveCancel={@bound 'onRemoveCancel'}
      onSave={@bound 'onSave'}
      onInputChange={@bound 'onInputChange'} />

