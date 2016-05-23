kd              = require 'kd'
React           = require 'kd-react'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'
Encoder         = require 'htmlencode'
showError       = require 'app/util/showError'


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
      logopath: '/a/images/logos/sidebar_footer_logo.svg'
      canEdit: canEdit
      loading: no


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
      TeamFlux.actions.uploads3({ name, content, mimeType }).then ({ url }) =>
        dataToUpdate =
          customize:
            logo: url
        @updateTeam { dataToUpdate }

      .catch ({ err }) ->
        showError err  if err

    reader.readAsDataURL file


  onClickLogo: ->

    @refs.view.input.click()


  onRemoveLogo: ->

    dataToUpdate =
      customize:
        logo: @state.logopath
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
      @setState { loading: no }
    .catch ({ message }) =>
      notify message
      @setState { loading: no }


  onTeamNameChanged: (event) ->

    @setState
      teamName : event.target.value


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
      canEdit={@state.canEdit}
      loading={@state.loading}
      logopath={@state.logopath}
      onUploadInput={@bound 'onUploadInput'}
      onClickLogo={@bound 'onClickLogo'}
      onRemoveLogo={@bound 'onRemoveLogo'}
      onUpdate={@bound 'onUpdate'}
      onLeaveTeam={@bound 'onLeaveTeam'}
      onTeamNameChanged={@bound 'onTeamNameChanged'}/>




HomeTeamSettingsContainer.include [KDReactorMixin]
