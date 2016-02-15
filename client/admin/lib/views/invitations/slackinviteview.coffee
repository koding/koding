kd    = require 'kd'

module.exports = class SlackInviteView extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = 'information'

    super options, data

    @createInformationView()
    @createOAuthButton()
    @createChannelSelector()


  createInformationView : -> @setPartial "<p>Invite your teammates using your company's Slack account.</p>"

  createOAuthButton: ->

    @addSubView new kd.ButtonView
      cssClass : 'solid medium green slack-oauth'
      title    : 'Integrate with <cite></cite>'

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
      cssClass : 'solid medium green invite-members'
      title    : 'Invite using Slack'
