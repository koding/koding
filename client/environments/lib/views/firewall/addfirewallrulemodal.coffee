kd = require 'kd'
$ = require 'jquery'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDModalViewWithForms = kd.ModalViewWithForms
KDNotificationView = kd.NotificationView
FirewallFilterFormView = require './firewallfilterformview'
remote = require('app/remote').getInstance()
globals = require 'globals'
showError = require 'app/util/showError'
KodingSwitch = require 'app/commonviews/kodingswitch'
Encoder = require 'htmlencode'


module.exports = class AddFirewallRuleModal extends KDModalViewWithForms

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
              defaultValue    : Encoder.htmlDecode data?.name
              validate        :
                rules         :
                  required    : yes
                messages      :
                  required    : "Please enter a rule name"
            enabled           :
              label           : "Enabled"
              cssClass        : "half"
              name            : "isEnabled"
              itemClass       : KodingSwitch
              defaultValue    : data?.enabled ? yes
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
      title     : "Add more filters"
      icon      : yes
      iconClass : "plus"
      cssClass  : "solid green small add-rule"
      callback  : @bound "createRuleWidget"

    disclaimer  = new KDCustomHTMLView
      cssClass  : "beta"
      partial   : "<span class='icon'></span> This is a beta feature."

    @modalTabs.forms.Rules.buttonField.addSubView button, null, yes
    @modalTabs.forms.Rules.buttonField.addSubView disclaimer

    {countries} = globals.config
    if countries then @setCountries() else @fetchCountries()

  createRuleWidget: (removable = yes, data = null) ->
    widget = new FirewallFilterFormView { removable }, data
    widget.on "FirewallFilterRemoved", =>
      @filterWidgets.splice @filterWidgets.indexOf(widget), 1
      @setPositions()

    @modalTabs.forms.Rules.fields.container.addSubView widget
    @filterWidgets.push widget
    widget.setCountries()  if globals.config.countries

  createExistingRules: ->
    @getData().rules.forEach (rule, index) =>
      @createRuleWidget yes, rule

  handleFormSubmit: ->
    isValid          = yes
    ruleTypes        = [ "request.second", "request.minute" ]
    hasRequestFilter = no

    for widget in @filterWidgets
      {type} = widget.inputs
      if ruleTypes.indexOf(type.getValue()) > -1
        isValid = no  if hasRequestFilter
        hasRequestFilter = yes

    return @notify "You can select only one request type filter" unless isValid

    {name, isEnabled} = @modalTabs.forms.Rules.getFormData()
    rules = []

    for widget in @filterWidgets
      data = widget.getFormData()
      if data.type is "country" then data.match = data.countries
      else if data.match is ""  then isValid = no

      delete data.countries
      rules.push data

    return @notify "Filter value is empty" unless isValid

    data    = @getData()
    dataSet = { name, rules, enabled: isEnabled }

    return @notify "You should have at least one filter"  if rules.length is 0

    if data
      data.update dataSet, (err, rule) =>
        return showError err  if err
        data.name    = name
        data.title   = name
        data.rules   = rules
        data.enabled = isEnabled
        @emit "RuleUpdated"
        @destroy()
    else
      remote.api.JProxyFilter.create dataSet, (err, rule) =>
        return @notify err.message  if err
        @emit "NewRuleAdded", rule

  fetchCountries: ->
    $.ajax
      type          : "GET"
      url           : "https://koding-cdn.s3.amazonaws.com/public/countries.js"
      dataType      : "jsonp"
      jsonp         : false
      jsonpCallback : "callback"
      success       : (countries) =>
        globals.config.countries = countries
        @setCountries()
      error         : => @notify "Error while fetching countries"

  setCountries: ->
    widget.setCountries() for widget in @filterWidgets

  notify: (message, cssClass = "error") ->
    return new KDNotificationView
      title      : message
      cssClass   : cssClass
      type       : "mini"
      container  : this
      duration   : 4000
