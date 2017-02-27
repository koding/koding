_ = require 'lodash'
kd = require 'kd'
React = require 'app/react'
View = require './view'
getGroup = require 'app/util/getGroup'
getOAuthEndPoint = require 'app/util/getOAuthEndPoint'


saveGitHubConfig = (options = {}, callback) ->

  options = _.assign {}, options, { provider: 'github' }
  getGroup().setOAuth options, callback


module.exports = class GitHubContainer extends React.Component

  constructor: (props) ->

    super props

    @state = @makeInitialState()


  makeInitialState: ->
    return {
      enabled: no
      applicationId: ''
      applicationSecret: ''
      scope: 'user:email, repo'
      isConfirmModalOpen: no
      isSaving: no
      isRemoving: no
      err: null
    }


  componentDidMount: ->

    group = getGroup()

    return  unless group.config?.github?

    group.fetchDataAt 'github.applicationSecret', (err, applicationSecret) =>

      { github } = group.config

      @setState
        scope: github.scope
        enabled: github.enabled
        applicationId: github.applicationId
        applicationSecret: applicationSecret


  onInputChange: (field) -> (event) =>

    state = _.assign {}, @state
    state[field] = event.target.value

    @setState state


  onToggleChange: (enabled) ->

    @setState { enabled }

    # just show form if it's going from disabled to enabled.
    return  if enabled

    wasEnabled = getGroup().config?.github?.enabled

    return  if not wasEnabled

    @setState { isConfirmModalOpen: yes }


  onRemoveCancel: ->

    state = _.assign {}, @state,
      enabled: getGroup().config.github.enabled
      isConfirmModalOpen: no

    @setState state


  onRemoveSuccess: ->

    @setState { isRemoving: yes, enabled: false }

    options = _.pick @state, 'applicationId', 'applicationSecret', 'scope'
    options.enabled = no

    saveGitHubConfig options, (err) =>
      if err
      then @setState { enabled: yes }
      else
        @setState @makeInitialState()
        delete getGroup().config.github
        kd.singletons.mainController.emit 'IntegrationsUpdated'


  onSave: ->

    @setState { isSaving: yes }, =>

      # get data from the form/state
      options = _.pick @state, 'applicationId', 'applicationSecret', 'scope'

      # mark it as `enabled` to make sure.
      options.enabled = yes

      # save it to the config
      saveGitHubConfig options, (err, config) =>

        newState = _.pick options, 'applicationId', 'applicationSecret', 'scope'
        newState.err = err

        # JGroup.setOAuth will return updated scope (aka cleaned scope)
        # on successful save request, we need to update it on UI as well
        newState.scope = config?.scope ? options.scope

        newState.isSaving = no

        unless err
          getGroup().config ?= {}
          getGroup().config.github = { enabled: yes }
          kd.singletons.mainController.emit 'IntegrationsUpdated'

        @setState newState


  render: ->

    { enabled, applicationId, isRemoving, err, scope
      isSaving, applicationSecret, isConfirmModalOpen } = @state

    <View
      enabled={enabled}
      err={err}
      callbackUrl={getOAuthEndPoint 'github'}
      scope={scope}
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
