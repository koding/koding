kd                    = require 'kd'
JView                 = require 'app/jview'
KDView                = kd.View
KDButtonView          = kd.ButtonView
KDCustomHTMLView      = kd.CustomHTMLView
KDNotificationView    = kd.NotificationView
TeamsEarlyAccessForm  = require './teamsearlyaccessform'
isKoding              = require 'app/util/isKoding'


module.exports = class TeamsView extends KDView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    @earlyAccess = new KDCustomHTMLView
      cssClass  : 'early-access'

    @form = new TeamsEarlyAccessForm
      callback  : @bound 'doRequest'

    @earlyAccess.addSubView @form  if isKoding()


  doRequest: (data) ->

    data.campaign = 'teams-early-access'
    title         = 'Thank you! We\'ll let you know when we launch it!'

    $.ajax
      url       : '/-/teams/early-access'
      data      : data
      type      : 'POST'
      success   : =>

        new KDNotificationView
          title    : title
          duration : 3000

        @form.email.setValue ''

      error     : ({responseText}) =>

        responseText = title  if responseText is 'Already applied!'

        new KDNotificationView
          title    : responseText
          duration : 3000

        @form.email.setValue ''


  pistachio: ->
    """
      <h2>Koding for Teams is free for all users while in beta</h2>
      {{> @earlyAccess}}
      <div class="onboarding"></div>
    """
