kd = require 'kd'
TeamFlux = require 'app/flux/teams'
showError = require 'app/util/showError'
require('./styl/deleteteambutton.styl')

module.exports = class DeleteTeamButton extends kd.CustomHTMLView

  constructor: (options, data) ->

    options.cssClass = kd.utils.curry 'deleteteambutton', options.cssClass
    options.partial = 'DELETE TEAM'

    super options, data



  click: ->
    modalContent = '
    <p>
      <strong>CAUTION! </strong>You are going to delete your team. You and your
      team members will not be able to access this team again.
      This action <strong>CANNOT</strong> be undone.
    </p> <br>
    <p>Please enter your <strong>current password</strong> into the field below to continue: </p>'

    TeamFlux.actions.deleteTeam(modalContent).catch (err) ->
      showError err
