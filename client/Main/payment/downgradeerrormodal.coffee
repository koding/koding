class PaymentDowngradeErrorModal extends PaymentBaseModal

  initialState: KD.utils.dict()

  constructor: (options = {}, data) ->

    { state } = options

    @state = KD.utils.extend @initialState, state

    options.title    = 'Downgrading isn\'t possible'
    options.cssClass = KD.utils.curry 'downgrade-error-modal', options.cssClass

    super options, data


  buildErrorPartial = (error) ->
    """
      <div class='msg'>#{error.message}</div>
      <div class='description'>
        <strong>#{error.planTitle.capitalize()} Plan</strong> allows you to have
        <strong>#{error.allowed}</strong> #{error.name}
        but you are currently using <strong>#{error.usage}</strong> #{error.name}.
      </div>
    """


  initViews: ->

    @addSubView @errorMessage = new KDCustomHTMLView
      cssClass : 'downgrade-error-msg'
      partial  : buildErrorPartial @state.error

    @addSubView @closeButton = new KDButtonView
      style    : 'solid medium green'
      cssClass : 'submit-btn'
      partial  : 'CLOSE'
      callback : @bound 'cancel'


