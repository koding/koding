JView = require 'app/jview'
CustomLinkView = require 'app/customlinkview'


module.exports = class GroupsWebhookView extends JView

  constructor:->
    super
    @setClass 'webhook'
    @editLink = new CustomLinkView
      href    : '#'
      title   : 'Edit'
      click   : (event)=>
        event.preventDefault()
        @emit 'WebhookEditRequested'

  pistachio:->
    "{.endpoint{#(webhookEndpoint)}} {{> @editLink}}"


