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
          partial           : "Enter Billing Information"
          itemClass         : KDCustomHTMLView
          cssClass          : "billing-link"
          click             : =>
            @updateBillingInfo group
        history             :
          label             : "Billing Method"
          tagName           : "a"
          partial           : "Show Payment History"
          itemClass         : KDCustomHTMLView
          cssClass          : "billing-link"
          click             : =>
            new GroupPaymentHistoryModal {group}
        subscriptions       :
          label             : "Subscriptions"
          tagName           : "a"
          partial           : "Show Subscriptions"
          itemClass         : KDCustomHTMLView
          cssClass          : "billing-link"
          click             : =>
            new GroupSubscriptionsModal {group}
        sharedVM            :
          label             : "Shared VM"
          itemClass         : KDOnOffSwitch
          name              : "shared-vm"
          cssClass          : "hidden"
        vmDesc              :
          itemClass         : KDCustomHTMLView
          cssClass          : "vm-description hidden"
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
            { title : "$ 10",  value : "1000" }
            { title : "$ 20",  value : "2000" }
            { title : "$ 30",  value : "3000" }
            { title : "$ 50",  value : "5000" }
            { title : "$ 100", value : "10000" }
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
          cssClass          : "no-title"
          callback          : (state)=>
            if state
              @settingsForm.fields.approval.show()
            else
              @settingsForm.fields.approval.hide()
        approval            :
          label             : "Need Approval"
          itemClass         : KDOnOffSwitch
          name              : "require-approval"
          cssClass          : "no-title"

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
                   <br><br>
                   #{billing.cardNumber} - #{billing.cardMonth}/#{billing.cardYear} (#{billing.cardType})
                   <br><br>
                   #{billing.address1} #{billing.address2}
                   <br>
                   #{billing.city} #{billing.state} #{billing.zip}
                   """
      else
        cardInfo = "Enter Billing Information"
      @settingsForm.inputs.billing.updatePartial cardInfo
      callback err, billing

  pistachio:-> "{{> @settingsForm}}"