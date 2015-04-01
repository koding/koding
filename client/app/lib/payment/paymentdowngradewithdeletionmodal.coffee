kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
PaymentBaseModal = require './paymentbasemodal'
showError = require '../util/showError'


module.exports = class PaymentDowngradeWithDeletionModal extends PaymentBaseModal

  getInitialState: -> kd.utils.dict()

  constructor: (options = {}, data) ->

    { state } = options

    @state = kd.utils.extend @getInitialState(), state

    options.title    = 'Downgrade your plan'
    options.cssClass = kd.utils.curry 'downgrade-with-deletion-modal', options.cssClass

    super options, data


  buildDescriptionPartial: ->
    
    { planTitle } = @state

    return """
      You are currently using more resources than <strong>#{planTitle.capitalize()}</strong> plan allows.
      Downgrading will <strong>delete your existing VM(s) and all the data inside them</strong> and give you
      new default VM. <strong>This action cannot be undone!</strong>
      <br /><br />
      Are you sure you want to continue?
    """


  initViews: ->

    @addSubView @subtitle = new KDCustomHTMLView
      cssClass : 'summary clearfix'
      partial  : @buildSubtitlePartial()

    @addSubView @description = new KDCustomHTMLView
      cssClass : 'description'
      partial  : @buildDescriptionPartial()

    @addSubView @submitButton = new KDButtonView
      style    : 'solid medium green'
      cssClass : 'submit-btn warning-btn'
      loader   : yes
      title  : 'YES, DOWNGRADE'
      callback : => @emit 'PaymentDowngradeWithDeletionSubmitted'


  initEvents: ->

    @on 'PaymentFailed',    @bound 'handleError'
    @on 'PaymentSucceeded', @bound 'handleSuccess'


  buildSubtitlePartial: ->

    { planTitle, planInterval, reducedMonth, monthPrice } = @state

    priceMap =
      month : "#{monthPrice}<span>/month</span>"
      year  : "#{reducedMonth}<span>/month</span>"

    return """
      <div class='plan-name'>#{planTitle.capitalize()} Plan</div>
      <div class='plan-price'>#{priceMap[planInterval]}</div>
    """


  handleError: (err) ->

    msg = err?.description or err?.message or "Something went wrong."
    showError msg


  handleSuccess: ->

    @setTitle 'Downgrade complete.'
    @description.destroy()
    @submitButton.hideLoader()
    @submitButton.setTitle 'CONTINUE'
    @submitButton.unsetClass 'warning-btn'
    @submitButton.setCallback =>
      @submitButton.hideLoader()
      @emit 'PaymentWorkflowFinished', @state
