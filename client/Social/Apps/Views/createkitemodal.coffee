class CreateKiteModal extends KDModalViewWithForms

  constructor: (options = {}, data) ->

    options.title             = "Create new Kite"
    options.overlay           = yes
    options.content           = ""
    options.cssClass          = "create-kite-modal"
    options.width             = 760
    options.height            = "auto"
    options.tabs              =
      # navigable               : no
      forms                   :
        Details               :
          buttons             :
            Next              :
              title           : "Next"
              style           : "modal-clean-gray"
              type            : "submit"
              loader          :
                color         : "#444444"
              callback        : -> @hideLoader()
            Cancel            :
              title           : "Cancel"
              style           : "modal-cancel"
              callback        : => @destroy()
          fields              :
            nameField         :
              label           : "Name"
              name            : "name"
              placeholder     : "Name of your Kite"
              validate        :
                rules         :
                  required    : yes
                messages      :
                  required    : "Please enter a kite name"
            descriptionField  :
              label           : "Description"
              name            : "description"
              placeholder     : "Description of your Kite"
              validate        :
                rules         :
                  required    : yes
                messages      :
                  required    : "Please enter a kite name"
        Pricing               :
          fields              :
            container         :
              itemClass       : KDView
              cssClass        : "pricing-items"
          buttons             :
            Save              :
              title           : "Save"
              style           : "modal-clean-gray"
              type            : "submit"
              loader          :
                color         : "#444444"
              callback        : @bound "save"
            Cancel            :
              title           : "Cancel"
              style           : "modal-cancel"
              callback        : => @destroy()

    super options, data

    @pricingForms = []

    @modalTabs.forms.Pricing.addSubView new KDButtonView
      title    : "ADD NEW"
      cssClass : "solid green small add-pricing"
      callback : @bound "createPricingView"

    @createPricingView()

  createPricingView: ->
    pricingForm = new KitePricingFormView

    @modalTabs.forms.Pricing.fields.container.addSubView pricingForm
    @pricingForms.push pricingForm

  save: ->
    details = @modalTabs.forms.Details.getFormData()
    plans   = (form.getFormData() for form in @pricingForms)

    KD.remote.api.JKite.create details, (err, kite)=>
      return  KD.showError err if err
      {dash} = Bongo
      queue = plans.map (plan) -> ->
        kite.createPlan plan, (err, kiteplan)->
          return queue.fin err  if err
          queue.fin()

      dash queue, (err) =>
        return KD.showError err if err
        @destroy()


class KitePricingFormView extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    options.cssClass      = "kite-pricing-view"
    options.fields        =
      planId              :
        label             : "Plan Id"
        name              : "planId"
        cssClass          : "thin half"
        nextElement       :
          planName        :
            label         : "Plan Name"
            name          : "planName"
            cssClass      : "thin half"
      planprice           :
        label             : "Plan Price"
        name              : "planPrice"
        cssClass          : "thin half"
        nextElement       :
          planRecurring   :
            cssClass      : "thin half"
            label         : "Recurring"
            type          : "select"
            itemClass     : KDSelectBox
            name          : "planRecurring"
            defaultValue  : "free"
            selectOptions : [
              { title     : "Free",      value : "free"    }
              { title     : "Monthly",   value : "monthly" }
              { title     : "Yearly",    value : "yearly"  }
            ]
      planDescription     :
        label             : "Plan Description"
        name              : "planDescription"
        type              : "textarea"

    super options, data