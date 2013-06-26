class GroupPaymentSettingsView extends JView

  constructor:->
    super
    @setClass "paymment-settings-view group-admin-modal"
    group = @getData()

    formOptions =
      callback:(formData)=>
        saveButton = @settingsForm.buttons.Save

        if formData['allow-over-usage']
          if formData['require-approval']
            overagePolicy = 'by permission'
          else
            overagePolicy = 'allowed'
        else
          overagePolicy = 'not allowed'

        # TODO: Delete shared VM if it's disabled?

        group.updateBundle
          overagePolicy: overagePolicy
          sharedVM     : formData['shared-vm']
          allocation   : formData.allocation
        , ->
          saveButton.hideLoader()

      buttons:
        Save                :
          style             : "modal-clean-green"
          type              : "submit"
          loader            :
            color           : "#444444"
            diameter        : 12
      fields                :
        billing             :
          label             : "Billing Method"
          tagName           : "a"
          partial           : ""
          itemClass         : KDCustomHTMLView
          cssClass          : "billing-link"
          click             : =>
            @updateBillingInfo group
        sharedVM            :
          label             : "Shared VM"
          itemClass         : KDOnOffSwitch
          name              : "shared-vm"
        vmDesc              :
          itemClass         : KDCustomHTMLView
          cssClass          : "vm-description"
          partial           : """<section>
                                <p>If you enable this, your group will have a shared VM.</p>
                              </section>"""
        allocation          :
          itemClass         : KDSelectBox
          label             : "Resources"
          type              : "select"
          name              : "allocation"
          defaultValue      : "0"
          selectOptions     : [
            { title : "None",  value : "0" }
            { title : "$ 10",  value : "10" }
            { title : "$ 20",  value : "20" }
            { title : "$ 30",  value : "30" }
            { title : "$ 50",  value : "50" }
            { title : "$ 100", value : "100" }
          ]
        allocDesc           :
          itemClass         : KDCustomHTMLView
          cssClass          : "alloc-description"
          partial           : """<section>
                                <p>You can pay for your members' resources. Each member's 
                                payment up to a specific amount will be charged from your 
                                balance.</p>
                              </section>"""
        overagePolicy       :
          label             : "Over-usage"
          itemClass         : KDOnOffSwitch
          name              : "allow-over-usage"
          callback          : (state)=>
            if state
              @settingsForm.fields.approval.show()
            else
              @settingsForm.fields.approval.hide()
        approval            :
          label             : "Need Approval"
          itemClass         : KDOnOffSwitch
          name              : "require-approval"
        overageDesc         :
          itemClass         : KDCustomHTMLView
          cssClass          : "overage-description"
          partial           : """<section>
                                <p>Resource overage description here...</p>
                              </section>"""

    @settingsForm = new KDFormViewWithFields formOptions, group

    @getBillingInfo group

    group.fetchBundle (err, bundle)=>
      if bundle.allocation
        @settingsForm.inputs.allocation.setValue bundle.allocation

      if bundle.sharedVM
        @settingsForm.inputs.sharedVM.setOn()

      @settingsForm.fields.approval.hide()
      if bundle.overagePolicy is "by permission"
        @settingsForm.inputs.overagePolicy.setOn()
        @settingsForm.inputs.approval.setOn()
        @settingsForm.fields.approval.show()
      else if bundle.overagePolicy is "allowed"
        @settingsForm.inputs.overagePolicy.setOn()
        @settingsForm.fields.approval.show()

  updateBillingInfo:(group)->
    @getBillingInfo group, (err, data)=>
      if err or not data
        data = {}

      paymentController = KD.getSingleton "paymentController"
      paymentController.createPaymentMethodModal data, (newData, onError, onSuccess)=>
        group.setBillingInfo newData, (err, result)=>
          if err
            onError err
          else
            @getBillingInfo group
            onSuccess result

  getBillingInfo:(group, callback=->)->
    group.getBillingInfo (err, billing)=>
      unless err
        cardInfo = """
                   #{billing.cardFirstName} #{billing.cardLastName}
                   -
                   #{billing.cardNumber} - #{billing.cardMonth}/#{billing.cardYear} (#{billing.cardType})
                   """
      else
        cardInfo = ""
      @settingsForm.inputs.billing.updatePartial cardInfo
      callback err, billing

  pistachio:-> "{{> @settingsForm}}"