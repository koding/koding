class GroupsWebhookView extends JView

  constructor:->
    super
    @setClass 'webhook'
    @editLink = new CustomLinkView
      href    : '#'
      title   : 'Edit webhook'
      click   : (event)=>
        event.preventDefault()
        @emit 'WebhookEditRequested'

  pistachio:->
    "{.endpoint{#(webhookEndpoint)}}{{> @editLink}}"