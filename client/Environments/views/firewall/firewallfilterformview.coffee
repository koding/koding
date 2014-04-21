class FirewallFilterFormView extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    options.fields     =
      type             :
        label          : "Type"
        name           : "type"
        cssClass       : "half"
        itemClass      : KDSelectBox
        selectOptions  : [
          { title      : "IP"       ,  value : "ip"             }
          { title      : "Country"  ,  value : "country"        }
          { title      : "Req./sec" ,  value : "request.second" }
          { title      : "Req./min" ,  value : "request.minute" }
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
        placeholder    : "Type a value for your filter..."
        validate       :
          rules        :
            required   : yes
          messages     :
            required   : "Please select a filter type"
      action           :
        label          : "Action"
        name           : "action"
        cssClass       : "half action"
        itemClass      : KDSelectBox
        selectOptions  : [
          { title      : "Allow"            , value : "allow"      }
          { title      : "Block"            , value : "block"      }
          { title      : "Show secure page" , value : "securepage" }
        ]
        validate       :
          rules        :
            required   : yes
          messages     :
            required   : "Please select a action type"
      enabled          :
        label          : "Enabled"
        cssClass       : "half"
        itemClass      : KodingSwitch
        defaultValue   : yes
      remove           :
        itemClass      : KDCustomHTMLView
        cssClass       : "delete-button half"
        click          : =>
          @emit "FirewallFilterRemoved"
          @destroy()

    delete options.fields.remove  unless options.removable

    super options, data
