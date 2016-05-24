kd              = require 'kd'
React           = require 'kd-react'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'
Encoder         = require 'htmlencode'
showError       = require 'app/util/showError'
DEFAULT_LOGOPATH = '/a/images/logos/sidebar_footer_logo.svg'

notify = (title, duration = 5000) -> new kd.NotificationView { title, duration }

module.exports = class HomeTeamSettingsContainer extends React.Component

  getDataBindings: ->
    return {
      team: TeamFlux.getters.team
    }


  constructor: (props) ->

    super props

    canEdit = kd.singletons.groupsController.canEditGroup()
    @state =
      canEdit: canEdit
      loading: no
      teamNameChanged: no


  componentDidMount: ->

    teamName = if @state.team? then Encoder.htmlDecode @state.team.get 'title' else ''
    @setState
      teamName: teamName


  onUploadInput: ->


    [file] = @refs.view.input.files
    return  unless file
    @setState { loading: yes }
    reader = new FileReader
    reader.onload = (reader, event) =>

      name = "#{@state.team.get 'slug'}-logo-#{Date.now()}.png"
      mimeType = file.type
      content = file
      TeamFlux.actions.uploads3({ name, content, mimeType })
      .then ({ url }) =>
        dataToUpdate =
          customize:
            logo: url
        @updateTeam { dataToUpdate }

      .timeout 15000

      .catch ({ err }) =>
        showError err  if err
        showError 'There was a problem while uploading your logo, please try again later!'  unless err
        @setState { loading: no }

    reader.readAsDataURL file


  onClickLogo: ->

    @refs.view.input.click()


  onRemoveLogo: ->

    dataToUpdate =
      customize:
        logo: DEFAULT_LOGOPATH
    @updateTeam { dataToUpdate }


  onUpdate: ->

    dataToUpdate = {}
    title = @state.teamName

    if title isnt @state.team.get 'title'
      dataToUpdate.title = title

    return  unless dataToUpdate.title

    @updateTeam { dataToUpdate }


  updateTeam: ({ dataToUpdate }) ->

    TeamFlux.actions.updateTeam(dataToUpdate).then ({ message }) =>
      notify message
      @setState
        loading: no
        teamNameChanged: no
    .catch ({ message }) =>
      notify message
      @setState
        loading: no
        teamNameChanged: no


  onTeamNameChanged: (event) ->

    @setState { teamName : event.target.value }

    if @state.team.get('title') isnt event.target.value
      @setState { teamNameChanged: yes }
    else
      @setState { teamNameChanged: no }

  onLeaveTeam: (event) ->

    partial = '<p>
                <strong>CAUTION! </strong>You are going to leave your team and you will not be able to login again.
                This action <strong>CANNOT</strong> be undone.
              </p> <br>
              <p>Please enter <strong>current password</strong> into the field below to continue: </p>'

    TeamFlux.actions.leaveTeam(partial).catch (err) ->
      showError err


  render: ->

    <View
      ref='view'
      team={@state.team}
      teamName={@state.teamName}
      teamNameChanged={@state.teamNameChanged}
      canEdit={@state.canEdit}
      loading={@state.loading}
      logopath={DEFAULT_LOGOPATH}
      onUploadInput={@bound 'onUploadInput'}
      onClickLogo={@bound 'onClickLogo'}
      onRemoveLogo={@bound 'onRemoveLogo'}
      onUpdate={@bound 'onUpdate'}
      onLeaveTeam={@bound 'onLeaveTeam'}
      onTeamNameChanged={@bound 'onTeamNameChanged'}/>




HomeTeamSettingsContainer.include [KDReactorMixin]
