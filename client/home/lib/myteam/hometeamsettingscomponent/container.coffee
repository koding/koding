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
      team: TeamFlux.getters.loadTeam
    }


  constructor: (props) ->

    super props
    

  componentDidMount: ->
    
    canEdit = kd.singletons.groupsController.canEditGroup()
    teamName = Encoder.htmlDecode @state.team?.get 'title' ? ''
    
    @setState
      logopath : '/a/images/logos/sidebar_footer_logo.svg'
      canEdit : canEdit
      teamName : teamName


  upload: (content, mimeType ) ->

    timeout = 3e4

    name = "#{@state.team.get 'slug'}-logo-#{Date.now()}.png"

    s3upload { name, content, mimeType, timeout }, (err, url) =>

      return showError err   if err

      team = @state.team.updateIn(['customize', 'logo'], -> url)
      @setState {team}


  onUploadInput: ->

    [file] = @refs.view.refs.uploadInput.files
    @upload file, file.type


  onClickLogo: ->

    @refs.view.refs.uploadInput.click()


  onRemoveLogo: ->

    team = @state.team.updateIn(['customize', 'logo'], -> '')
    @setState {team}


  onUpdate: ->

    { groupsController, reactor } = kd.singletons
    team = groupsController.getCurrentGroup()

    title = @state.teamName
    dataToUpdate = {}
    dataToUpdate.title = title  unless title is @state.team.get 'title'

    logo = @state.team.getIn(['customize', 'logo'])
    dataToUpdate.customize = {}
    if logo
      dataToUpdate.customize.logo = logo
    else
      dataToUpdate.customize.logo = @state.logopath

    return  if _.isEmpty dataToUpdate

    TeamFlux.actions.updateTeam(dataToUpdate).then ({ message }) ->
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
