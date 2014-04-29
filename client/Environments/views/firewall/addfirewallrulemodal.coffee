class AddFirewallRuleModal extends KDModalViewWithForms

  constructor: (options = {}, data) ->

    options.overlay           = yes
    options.content           = ""
    options.cssClass          = "firewall-modal"
    options.width             = 735
    options.height            = "auto"
    options.tabs              =
      callback                : @bound "handleFormSubmit"
      forms                   :
        Rules                 :
          buttons             :
            Save              :
              title           : if data then "Update" else "Save"
              style           : "solid green compact"
              loader          :
                color         : "#444444"
              type            : "submit"
              callback        : -> @hideLoader()
            Cancel            :
              title           : "Cancel"
              style           : "solid gray compact"
              callback        : => @destroy()
          fields              :
            label             :
              itemClass       : KDCustomHTMLView
              cssClass        : "section-label first"
              partial         : "Define your firewall rule"
            name              :
              label           : "Name"
              name            : "name"
              cssClass        : "half"
              placeholder     : "Name of your rule"
              defaultValue    : data?.name
              validate        :
                rules         :
                  required    : yes
                messages      :
                  required    : "Please enter a rule name"
            description       :
              itemClass       : KDCustomHTMLView
              cssClass        : "section-label second"
              partial         : "<p>Add filters to your rule</p>"
            headers           :
              itemClass       : KDCustomHTMLView
              cssClass        : "header-row"
              partial         : """
                <h4 class="type">Type</h4>
                <h4 class="value">Value</h4>
                <h4 class="filter">Filter</h4>
                <h4 class="button">Delete</h4>
                <h4 class="state">Active?</h4>
              """
            container         :
              itemClass       : KDCustomHTMLView

    super options, data

    @filterWidgets = []
    if data then @createExistingRules() else @createRuleWidget no

    button      = new KDButtonView
      title     : "Add more rules"
      icon      : yes
      iconClass : "plus"
      cssClass  : "solid green small add-rule"
      callback  : @bound "createRuleWidget"

    @modalTabs.forms.Rules.buttonField.addSubView button, null, yes

  createRuleWidget: (removable = yes, data = null) ->
    widget = new FirewallFilterFormView { removable }, data
    widget.on "FirewallFilterRemoved", =>
      @filterWidgets.splice @filterWidgets.indexOf(widget), 1

    @modalTabs.forms.Rules.fields.container.addSubView widget
    @filterWidgets.push widget

  createExistingRules: ->
    @getData().rules.forEach (rule, index) =>
      @createRuleWidget index isnt 0, rule

  handleFormSubmit: ->
    isValid          = yes
    ruleTypes        = [ "request.second", "request.minute" ]
    hasRequestFilter = no

    for widget in @filterWidgets
      {type} = widget.inputs
      if ruleTypes.indexOf(type.getValue()) > -1
        isValid = no  if hasRequestFilter
        hasRequestFilter = yes

    unless isValid
      return new KDNotificationView
        title      : "You can select only one request type filter"
        cssClass   : "error"
        type       : "mini"
        container  : this
        duration   : 4000

    {name} = @modalTabs.forms.Rules.getFormData()
    rules  = []

    rules.push form.getFormData() for form in @filterWidgets

    data = @getData()
    if data
      data.update { name, rules }, (err, rule) =>
        return KD.showError err  if err
        data.name  = name
        data.title = name
        data.rules = rules
        @emit "RuleUpdated"
        @destroy()
    else
      KD.remote.api.JProxyFilter.create { name, rules }, (err, rule) =>
        return KD.showError err  if err
        @emit "NewRuleAdded", rule
