kd                        = require 'kd'
JView                     = require 'app/jview'

timeago                   = require 'timeago'
showError                 = require 'app/util/showError'
ActivityItemMenuItem      = require 'activity/views/activityitemmenuitem'
GroupsDangerModalView     = require 'admin/views/permissions/groupsdangermodalview'


module.exports = class TeamListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type   or= 'member'
    options.cssClass = kd.utils.curry "team-item clearfix", options.cssClass

    super options, data

    { inuse, privacy, config } = @getData()

    @roleLabel = new kd.CustomHTMLView
      cssClass : 'role'
      partial  : "Details <span class='settings-icon'></span>"
      click    : @getDelegate().lazyBound 'toggleDetails', this

    @createDetailsView()


  createDetailsView: ->

    team = @getData()

    @details = new kd.CustomHTMLView
      cssClass : 'hidden'

    message = if plan = team.config?.plan
    then "Current plan is #{plan}."
    else 'Currently no plan is set, which means there is no limit for this team.'

    @details.addSubView new kd.View partial: message
    @details.addSubView new kd.ButtonView
      title    : 'Change Team Plan'
      cssClass : 'solid compact'
      callback : -> console.log 'WIP', team

    @details.addSubView new kd.ButtonView
      title    : 'Destroy Team'
      cssClass : 'solid compact red'
      callback : ->
        modal = new GroupsDangerModalView
          action     : 'Destroy Team'
          longAction : 'destroy whole team'
          callback   : ->
            team.destroy (err) ->
              return  if showError err
              modal.destroy()
        , team


  toggleDetails: ->

    @details.toggleClass  'hidden'
    @roleLabel.toggleClass 'active'

  pistachio: ->

    """
      {div.details{#(title)}}
      {{> @roleLabel}}
      <div class='clear'></div>
      {{> @details}}
    """
