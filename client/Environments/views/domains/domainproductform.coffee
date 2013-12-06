class DomainProductForm extends JView

  viewAppended: ->

    locationController = KD.getSingleton 'locationController'

    @locationForm = locationController.createLocationForm
      callback            : =>
        @emit 'DataCollected', @locationForm.getData()

      fields              :
        privacyProtection :
          label           : "Use privacy protection?"
          itemClass       : KDOnOffSwitch
          labels          : ['yes', 'no']

      phone               :
        required          : yes

    super()

  processForm: ->
    @locationForm.submit()

  pistachio: ->
    """
    <div class='modalformline'>
      <p>
        Please enter the address information that will be associated with this
        domain name registration.  You can choose to register this domain
        privately for an additional fee.
      </p>
    </div>
    {{> @locationForm}}
    """