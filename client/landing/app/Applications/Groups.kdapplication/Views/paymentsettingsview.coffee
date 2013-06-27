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
          label             : "History"
          tagName           : "a"
          partial           : "Show Payment History"
          itemClass         : KDCustomHTMLView
          cssClass          : "billing-link"
          click             : =>
            new GroupPaymentHistoryModal {group}
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
                   <br><br>
                   #{billing.cardNumber} - #{billing.cardMonth}/#{billing.cardYear} (#{billing.cardType})
                   <br><br>
                   #{billing.address1} #{billing.address2}
                   <br>
                   #{billing.city}, #{billing.state} #{billing.zip}
                   """
      else
        cardInfo = "Enter Billing Information"
      @settingsForm.inputs.billing.updatePartial cardInfo
      callback err, billing

  pistachio:-> "{{> @settingsForm}}"

class GroupPaymentHistoryModal extends KDModalViewWithForms

  constructor:(options, data)->
    {group} = options

    options =
      title                   : "Payment History"
      content                 : ''
      overlay                 : yes
      width                   : 500
      height                  : "auto"
      cssClass                : "databases-modal"
      tabs                    :
        navigable             : yes
        goToNextFormOnSubmit  : no
        forms                 :
          history             :
            fields            :
              Instances       :
                type          : 'hidden'
                cssClass      : 'database-list'
            buttons           :
              Refresh         :
                style         : "modal-clean-gray"
                type          : 'submit'
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : =>
                  form = @modalTabs.forms.history
                  @dbController.loadItems =>
                    form.buttons.Refresh.hideLoader()

    super options, data

    @dbController = new GroupPaymentHistoryListController
      group     : group
      itemClass : AccountPaymentHistoryListItem

    dbList = @dbController.getListView()

    dbListForm = @modalTabs.forms.history
    dbListForm.fields.Instances.addSubView @dbController.getView()

    @dbController.loadItems()

class GroupPaymentHistoryListController extends KDListViewController

  constructor:(options = {}, data)->
    @group = options.group
    super

  loadView:->

    super
    @loadItems()

  loadItems:(callback)->
    @removeAllItems()
    @customItem?.destroy()
    @showLazyLoader no

    transactions = []
    @group.checkPayment (err, trans) =>
      if err
        @instantiateListItems []
        @hideLazyLoader()
      unless err
        for t in trans
          if t.amount + t.tax is 0
            continue
          transactions.push
            status     : t.status
            amount     : ((t.amount + t.tax) / 100).toFixed(2)
            currency   : 'USD'
            createdAt  : t.datetime
            paidVia    : t.card or ""
            owner      : t.owner
            refundable : t.refundable
        if transactions.length is 0
          @addCustomItem "There are no transactions."
        else
          @instantiateListItems transactions
        @hideLazyLoader()
        callback?()

  addCustomItem:(message)->
    @removeAllItems()
    @customItem?.destroy()
    @scrollView.addSubView @customItem = new KDCustomHTMLView
      cssClass : "no-item-found"
      partial  : message