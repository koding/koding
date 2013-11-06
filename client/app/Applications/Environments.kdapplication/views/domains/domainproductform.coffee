class DomainProductForm extends JView

  viewAppended: ->
    locationController = KD.getSingleton 'locationController'
    locationForm = locationController.createLocationForm
      callback    : => @emit 'DataCollected', @locationForm.getData()
      buttons     : no
      phone       :
        required  : yes

    @locationForm = locationForm

    @privacyProtection = new KDFormViewWithFields
      fields         :
        enabled      :
          label      : 'Use privacy protection?'
          itemClass  : KDOnOffSwitch
          callback   : -> 
            do locationForm[if @getValue() is on then 'hide' else 'show']

    privacyExplanation = new KDView
      partial: "We'll mask your address information.  Blah blah blah."

    @privacyExplanation = privacyExplanation

    @privacyExplanation.hide()

    @buttons = new KDView

    @saveBtn = new KDButtonView
      title     : "Next"
      style     : 'modal-clean-green fr'
      callback  : @bound 'processForm'

    @buttons.addSubView @saveBtn

    super()

  processForm: ->
    privacyEnabled = @privacyProtection.inputs.enabled.getValue()
    if privacyEnabled is on
      @emit 'DataCollected', privacyProtection: on
    else
      @locationForm.submit()

  pistachio: ->
    """
    <p>Please enter the address information that will be associated with this
       domain name registration.  Alternatively, you can choose to register
       this domain privately for an additional fee.</p>
    {{> @privacyProtection}}
    {{> @privacyExplanation}}
    {{> @locationForm}}
    {{> @buttons}}
    """