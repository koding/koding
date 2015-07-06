kd    = require 'kd'
JView = require 'app/jview'


module.exports = class CredentialListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'credential-item clearfix', options.cssClass
    super options, data

    delegate = @getDelegate()
    { publicKey, owner, title, verified } = @getData()

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
      cssClass : 'inuse-tag hidden'
      partial  : 'IN USE'
      tooltip  :
        title  : 'This stack template currently using this credential'

    {stackTemplate} = @getOptions()
    if stackTemplate?.credentials? and publicKey in stackTemplate.credentials
      @inuseView.show()

    @warningView = new kd.CustomHTMLView
      cssClass : 'warning-message hidden'


  setVerified: (state, reason) ->

    if state
      @warningView.hide()
      @getDelegate().emit 'ItemSelected', @getData()
    else
      @warningView.updatePartial if reason
        "Failed to verify: #{reason}"
      else
        "We couldn't verify this credential, please check the ones you
         used or add a new credential to be able to continue to the
         next step."

      @warningView.show()


  verifyCredential: ->

    {publicKey} = @getData()

    @warningView.hide()

    @getDelegate()
      .verify this
      .timeout 5000
      .then (response) =>
        @setVerified response?[publicKey]

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
