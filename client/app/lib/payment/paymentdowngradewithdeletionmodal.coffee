kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDLoaderView = kd.LoaderView
PaymentBaseModal = require './paymentbasemodal'
showError = require 'app/util/showError'


module.exports = class PaymentDowngradeWithDeletionModal extends PaymentBaseModal

  constructor: (options = {}, data) ->

    options.title    = 'Downgrade your plan'
    options.cssClass = kd.utils.curry 'downgrade-with-deletion-modal', options.cssClass

    super options, data

    @state = options.state


  buildDescriptionPartial: ->

    { state: { planTitle } } = @getOptions()

    return """
      You are currently using more resources than <strong>#{planTitle.capitalize()}</strong> plan allows.
      Downgrading will <strong>delete your existing VM(s) and all the data inside them</strong> and give you
      new default VM. <strong>This action cannot be undone!</strong>
      <br /><br />
      Are you sure you want to continue?
    """


  initViews: ->

    @addSubView @subtitle     = new KDCustomHTMLView
      cssClass : 'summary clearfix'
      partial  : @buildSubtitlePartial()

    @addSubView @description  = new KDCustomHTMLView
      cssClass : 'description'
      partial  : @buildDescriptionPartial()

    @addSubView @loaderLabel  = new KDCustomHTMLView
      cssClass : "loader-label"
      partial  : ''
    @loaderLabel.hide()

    @addSubView @loader       = new KDLoaderView
      showLoader : yes
      size       :
        width    : 40
        height   : 40
    @loader.hide()

    @addSubView @submitButton = new KDButtonView
      style    : 'solid medium green'
      cssClass : 'submit-btn warning-btn'
      title  : 'YES, DOWNGRADE'
      callback : @lazyBound 'emit', 'PaymentDowngradeWithDeletionSubmitted'


  initEvents: ->

    @on 'DestroyingMachinesStarted', @bound 'handleDestroyingStep'
    @on 'DowngradingStarted',        @bound 'handleDowngradingStep'
    @on 'PaymentSucceeded',          @bound 'handleSuccess'
    @on 'PaymentFailed',             @bound 'handleError'


  buildSubtitlePartial: ->

    { state: { planTitle, planInterval, reducedMonth, monthPrice } } = @getOptions()

    priceMap =
      month : "#{monthPrice}<span>/month</span>"
      year  : "#{reducedMonth}<span>/month</span>"

    return """
      <div class='plan-name'>#{planTitle.capitalize()} Plan</div>
      <div class='plan-price'>#{priceMap[planInterval]}</div>
    """


  handleDestroyingStep: ->

    @description.hide()
    @loader.show()
    @loaderLabel.updatePartial 'Deleting your VM(s)...'
    @loaderLabel.show()
    @submitButton.hide()


  handleDowngradingStep: -> @loaderLabel.updatePartial 'Downgrading...'


  handleSuccess: ->

    @setTitle 'Downgrade complete'
    @loader.hide()
    @loaderLabel.hide()
    @submitButton.setTitle 'CONTINUE'
    @submitButton.unsetClass 'warning-btn'
    @submitButton.setCallback => @emit 'PaymentWorkflowFinished', @state
    @submitButton.show()


  handleError: (err) ->

    showError err?.description or err?.message or "Something went wrong."
