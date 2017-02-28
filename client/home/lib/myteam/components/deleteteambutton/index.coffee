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

    TeamFlux.actions.deleteTeam().catch (err) ->
      showError err
