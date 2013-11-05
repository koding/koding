class VmBuyModal extends BuyModal

  constructor: (options = {}, data) ->
    options.title ?= "Create a new VM"
    super options, data

  createProductForm: ->
    { hostTypes, descriptions, descPartial, plans } = @getOptions()

    canCreateSharedVM   = "owner" in KD.config.roles or "admin" in KD.config.roles
    canCreatePersonalVM = "member" in KD.config.roles

    group = KD.getSingleton("groupsController").getGroupSlug()

    if canCreateSharedVM
      content = """You can create a <b>Personal</b> or <b>Shared</b> VM for
                   <b>#{group}</b>. If you prefer to create a shared VM, all
                   members in <b>#{group}</b> will be able to use that VM.
                """
    else if canCreatePersonalVM
      content = """You can create a <b>Personal</b> VM in <b>#{group}</b>."""
    else
      return new KDNotificationView
        title : "You are not authorized to create VMs in #{group} group"

    modal = this

    form = new KDFormViewWithFields
      callback              : (formData) =>
        @addAggregateData formData
        @preparePaymentMethods()
      buttons               :
        user                :
          title             : "Create a <b>Personal</b> VM"
          style             : "modal-clean-gray"
          type              : "submit"
          loader            :
            color           : "#ffffff"
            diameter        : 12
          callback          : ->
            form.inputs.type.setValue "user"
        expensed            :
          title             : "Create a <b>Personal</b> VM, Charge Group"
          style             : "modal-clean-gray hidden"
          type              : "submit"
          loader            :
            color           : "#ffffff"
            diameter        : 12
          callback          : ->
            form.inputs.type.setValue "expensed"
        group               :
          title             : "Create a <b>Shared</b> VM"
          style             : "modal-clean-gray hidden"
          type              : "submit"
          loader            :
            color           : "#ffffff"
            diameter        : 12
          callback          : ->
            form.inputs.type.setValue "group"
        cancel              :
          style             : "modal-cancel"
          callback          : -> modal.destroy()
      fields                :
        "intro"             :
          itemClass         : KDCustomHTMLView
          partial           : "<p>#{content}</p>"
        selector            :
          name              : "host"
          itemClass         : HostCreationSelector
          cssClass          : "host-type"
          radios            : hostTypes
          defaultValue      : 0
          validate          :
            rules           :
              required      : yes
            messages        :
              required      : "Please select a VM type!"
          change            : ->
            modal.currentPlan = plans[@getValue()]
        desc                :
          itemClass         : KDCustomHTMLView
          cssClass          : "description-field hidden"
          partial           : descPartial
        type                :
          name              : "type"
          type              : "hidden"
          # Check user quota and show this button only when necessary

    KD.getGroup().checkUserBalance {}, (err, limit=0, balance=0) =>
      warn err  if err

      index      = (parseInt form.inputs.selector.getValue(), 10) or 0
      monthlyFee = plans[index].feeAmount

      if limit > 0
        credits = (limit / 100).toFixed 2

        creditsMessage = "<p>This group gives you $#{credits} credits.</p>"
        if balance > 0
          spent = (balance / 100).toFixed 2
          creditsMessage += "<p>You've spent $#{spent}.</p>"

        form.fields.desc.setPartial creditsMessage
        form.fields.desc.show()

        if limit >= balance + monthlyFee
          modal.modalTabs.forms["Create VM"].buttons.expensed.show()

    hideLoaders = ->
      {group, user, expensed} = form.buttons
      user.hideLoader()
      expensed.hideLoader()
      group.hideLoader()

    # vmController.on "PaymentModalDestroyed", hideLoaders

    form.buttons.group.show()  if canCreateSharedVM

    form.on "FormValidationFailed", hideLoaders