class DomainProductForm extends JView

  viewAppended: ->
    locationController = KD.getSingleton 'locationController'
    
    @locationForm = locationController.createLocationForm
      callback    : =>
        @emit 'DataCollected', @locationForm.getData()
      fields      :
        privacyProtection:
          label   : "Use privacy protection?"
          itemClass: KDOnOffSwitch
      phone       :
        required  : yes


    # @buttons = new KDView

    # @saveBtn = new KDButtonView
    #   title     : "Next"
    #   style     : 'modal-clean-green fr'
    #   callback  : @bound 'processForm'

    # @buttons.addSubView @saveBtn

    super()

  processForm: ->
    @locationForm.submit()

  pistachio: ->
    """
    <p>Please enter the address information that will be associated with this
       domain name registration.  Alternatively, you can choose to register
       this domain privately for an additional fee.</p>
    {{> @locationForm}}
    """