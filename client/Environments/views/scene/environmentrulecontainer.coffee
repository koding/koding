class EnvironmentRuleContainer extends EnvironmentContainer

  EnvironmentDataProvider.addProvider "rules", ->

    dummyRules = [
      {
        title: "Allow All",
        description: "allow from *"
      }
    ]

    new Promise (resolve, reject)->
      resolve dummyRules

  constructor:(options={}, data)->

    options.cssClass  = 'firewall'
    options.itemClass = EnvironmentRuleItem
    options.title     = 'firewall rules'

    super options, data

    @on 'PlusButtonClicked', -> new AddFirewallRuleModal


class AddFirewallRuleModal extends KDModalViewWithForms

  constructor: (options = {}, data) ->

    options.overlay           = yes
    options.content           = ""
    options.cssClass          = "firewall-modal"
    options.width             = 630
    options.height            = "auto"
    options.tabs              =
      callback                : @bound "handleFormSubmit"
      forms                   :
        Rules                 :
          buttons             :
            Save              :
              title           : "Save"
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
              validate        :
                rules         :
                  required    : yes
                messages      :
                  required    : "Please enter a rule name"
            action            :
              label           : "Action"
              name            : "action"
              cssClass        : "half"
              itemClass       : KDSelectBox
              selectOptions   : [
                { title       : "Allow"            , value : "allow"      }
                { title       : "Block"            , value : "block"      }
                { title       : "Show secure page" , value : "securepage" }
              ]
              validate        :
                rules         :
                  required    : yes
                messages      :
                  required    : "Please select a action type"
            description       :
              itemClass       : KDCustomHTMLView
              cssClass        : "section-label second"
              partial         : "<p>Add rules to your action</p>"
            container         :
              itemClass       : KDCustomHTMLView

    super options, data

    @ruleWidgets = []
    @createRuleWidget no

    button      = new KDButtonView
      title     : "Add more rules"
      icon      : yes
      iconClass : "plus"
      cssClass  : "solid green small add-rule"
      callback  : @bound "createRuleWidget"

    @modalTabs.forms.Rules.buttonField.addSubView button, null, yes

  createRuleWidget: (removable = yes) ->
    widget = new FirewallFilterWidget { removable }
    widget.on "FirewallFilterRemoved", =>
      @ruleWidgets.splice @ruleWidgets.indexOf(widget), 1

    @modalTabs.forms.Rules.fields.container.addSubView widget
    @ruleWidgets.push widget

  handleFormSubmit: ->
    isValid          = yes
    ruleTypes        = [ "request.second", "request.minute" ]
    hasRequestFilter = no

    for widget in @ruleWidgets
      {type} = widget.inputs
      if ruleTypes.indexOf(type.getValue()) > -1
        isValid = no  if hasRequestFilter
        hasRequestFilter = yes

    unless isValid
      return new KDNotificationView
        title     : "You can select only one request type filter"
        cssClass  : "error"
        type      : "mini"
        container : this
        duration  : 4000

class FirewallFilterWidget extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    options.fields     =
      type             :
        label          : "Type"
        name           : "type"
        cssClass       : "half"
        itemClass      : KDSelectBox
        selectOptions  : [
          { title      : "IP"                 ,  value : "ip"             }
          { title      : "Country"            ,  value : "country"        }
          { title      : "Request per second" ,  value : "request.second" }
          { title      : "Request per minute" ,  value : "request.minute" }
        ]
        validate       :
          rules        :
            required   : yes
          messages     :
            required   : "Please select a filter type"
      value            :
        label          : "Value"
        name           : "value"
        cssClass       : "half"
        validate       :
          rules        :
            required   : yes
          messages     :
            required   : "Please select a filter type"
      remove           :
        itemClass      : KDCustomHTMLView
        cssClass       : "delete-button half"
        click          : =>
          @emit "FirewallFilterRemoved"
          @destroy()

    unless options.removable
      delete options.fields.remove
      options.cssClass = KD.utils.curry "full", options.cssClass

    super options, data
