class KitePricingFormView extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    options.cssClass      = "kite-pricing-view"
    options.fields        =
      planId              :
        label             : "Plan Id"
        name              : "userTag"
        cssClass          : "thin half"
        nextElement       :
          planName        :
            label         : "Plan Name"
            name          : "title"
            cssClass      : "thin half"
      planprice           :
        label             : "Plan Price"
        name              : "feeAmount"
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
        name              : "description"
        type              : "textarea"

    super options, data
