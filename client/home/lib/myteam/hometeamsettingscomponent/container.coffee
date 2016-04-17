_               = require 'lodash'
kd              = require 'kd'
React           = require 'kd-react'
TeamFlux        = require 'app/flux/teams'
KDReactorMixin  = require 'app/flux/base/reactormixin'
View            = require './view'
Encoder         = require 'htmlencode'
s3upload        = require 'app/util/s3upload'
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


  componentDidMount: ->

    teamName = Encoder.htmlDecode @state.team?.get 'title' ? ''
    @setState
      teamName: teamName


  upload: (content, mimeType) ->

    timeout = 3e4

    name = "#{@state.team.get 'slug'}-logo-#{Date.now()}.png"

    s3upload { name, content, mimeType, timeout }, (err, url) =>

      return showError err   if err

      team = @state.team.setIn ['customize', 'logo'], url
      @setState {team}


  onUploadInput: ->

    [file] = @refs.view.input.files
    @upload file, file.type


  onClickLogo: ->

    @refs.view.input.click()


  onRemoveLogo: ->

    team = @state.team.updateIn(['customize', 'logo'], -> '')
    @setState {team}


  onUpdate: ->

    dataToUpdate =
      customize:
        logo: @state.logopath

    title = @state.teamName

    if title isnt @state.team.get 'title'
      dataToUpdate.title = title

    if logo = @state.team.getIn(['customize', 'logo'])
      dataToUpdate.customize.logo = logo

    TeamFlux.actions.updateTeam(dataToUpdate).then ({ message }) ->
      notify message
    .catch ({ message }) ->
      notify message

  onTeamNameChanged: (event)->

    @setState
      teamName : event.target.value


  render: ->

    <View
      ref='view'
      team={@state.team}
      teamName={@state.teamName}
      canEdit={@state.canEdit}
      logopath={@state.logopath}
      onUploadInput={@bound 'onUploadInput'}
      onClickLogo={@bound 'onClickLogo'}
      onRemoveLogo={@bound 'onRemoveLogo'}
      onUpdate={@bound 'onUpdate'}
      onTeamNameChanged={@bound 'onTeamNameChanged'}/>


HomeTeamSettingsContainer.include [KDReactorMixin]
