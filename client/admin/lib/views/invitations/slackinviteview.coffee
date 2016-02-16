kd    = require 'kd'

module.exports = class SlackInviteView extends kd.CustomScrollView

  SLACKBOT_ID = 'USLACKBOT'
  OAUTH_URL   = "#{location.origin}/api/social/slack/oauth"

  constructor: (options = {}, data) ->

    options.cssClass = 'information'

    super options, data

    @createInformationView()


  createInformationView : ->

    @wrapper.addSubView info = new kd.CustomHTMLView
      tagName  : 'p'
      cssClass : 'information'
      partial  : 'Invite your teammates using your company\'s Slack account.'

    info.addSubView button = new kd.ButtonView
      cssClass : 'solid medium green slack-oauth'

  createChannelSelector: ->

    @addSubView wrapper = new kd.CustomHTMLView

    wrapper.addSubView new kd.SelectBox
      defaultValue  : '--'
      callback      : (value) -> console.log value
      selectOptions : [
        title : 'Invite members of a public channel'
        value : '--'
      ,
        title : '#general'
        value : 'general'
      ,
        title : '#koding'
        value : 'koding'
      ,
        title : '#devs'
        value : 'devs'
      ]

    wrapper.addSubView new kd.SelectBox
      defaultValue  : '--'
      callback      : (value) -> console.log value
      selectOptions : [
        title : 'Invite members of a private channel'
        value : '--'
      ,
        title : 'devrim'
        value : 'devrim'
      ,
        title : 'sinan'
        value : 'sinan'
      ,
        title : 'selin'
        value : 'selin'
      ]

    wrapper.addSubView new kd.ButtonView
      title    : 'Import from  <cite></cite>'
      callback : =>

        cb = =>
          kd.utils.killRepeat repeat
          info.hide()
          @createInviterViews()

        oauth_window = window.open(
          OAUTH_URL,
          "slack-oauth-window",
          "width=800,height=#{window.innerHeight},left=#{Math.floor (screen.width/2) - 400},top=#{Math.floor (screen.height/2) - (window.innerHeight/2)}"
        )

        repeat = kd.utils.repeat 500, -> cb()  if oauth_window.closed


      cssClass : 'solid medium green invite-members'
      title    : 'Invite using Slack'
