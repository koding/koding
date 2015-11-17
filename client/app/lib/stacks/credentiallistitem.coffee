kd    = require 'kd'
JView = require 'app/jview'


module.exports = class CredentialListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'credential-item clearfix', options.cssClass
    super options, data

    delegate = @getDelegate()
    { identifier, owner, title, verified } = credential = @getData()

    @deleteButton = new kd.ButtonView
      cssClass : 'solid compact outline red secondary'
      title    : 'DELETE'
      callback : delegate.lazyBound 'deleteItem', this

    @showCredentialButton = new kd.ButtonView
      cssClass : 'solid compact outline secondary'
      title    : 'SHOW'
      callback : delegate.lazyBound 'showItemContent', this

    @verifyButton = new kd.ButtonView
      cssClass : 'solid compact outline'
      title    : 'USE THIS & CONTINUE'
      loader   :
        color  : '#666'
      callback : @bound 'verifyCredential'

    @inuseView = new kd.CustomHTMLView
      cssClass : 'custom-tag hidden'
      partial  : 'IN USE'
      tooltip  :
        title  : 'This stack template currently using this credential'

    { stackTemplate }       = @getOptions()
    { selectedCredentials } = delegate.getOptions()

    credentials = stackTemplate?.credentials ? {}
    credentials = (credentials[val].first for val of credentials)
    credentials = credentials.concat (selectedCredentials or [])

    if identifier in credentials
      credential.inuse = yes
      @inuseView.show()

    @warningView = new kd.CustomHTMLView
      cssClass : 'warning-message hidden'

    delegate.on 'ResetInuseStates', @inuseView.bound 'hide'


  setVerified: (state, reason) ->

    if state
      @warningView.hide()
      @getDelegate().emit 'ItemSelected', this
    else
      @warningView.updatePartial if reason
        "Failed to verify: #{reason}"
      else
        "We couldn't verify this credential, please check the ones you
         used or add a new credential to be able to continue to the
         next step."

      @warningView.show()


  verifyCredential: ->

    {identifier} = @getData()

    @warningView.hide()

    @getDelegate()
      .verify this
      .timeout 10000
      .then (response) =>
        @setVerified response?[identifier]

      .catch (err) =>
        @setVerified no, err.message

      .finally @verifyButton.bound 'hideLoader'


  pistachio: ->
    """
    <div class='credential-info clearfix'>
      {div.tag{#(provider)}} {div.title{#(title)}} {{> @inuseView}}
    </div>
    <div class='buttons'>
      {{> @showCredentialButton}}{{> @deleteButton}}{{> @verifyButton}}
    </div>
    {{> @warningView}}
    """
