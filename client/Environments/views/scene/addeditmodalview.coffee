class AddEditItemModal extends KDModalViewWithForms
  constructor : (options = {}) ->
    options.overlay  = yes
    options.cssClass = KD.utils.curry "add-edit-item", options.cssClass
    options.width    = 350

    options.tabs     =
      navigable         : no
      forms             :
        'Add New Rule'  :
          fields        :
            name        :
              label     : "Rule Name:"
              type      : "text"
              name      : "name"
            description :
              label     : "Description:"
              type      : "textarea"
              name      : "description"
            allow       :
              label     : "Allow:"
              type      : "textarea"
              name      : "allow"
            deny        :
              label     : "Deny:"
              type      : "textarea"
              name      : "deny"
            colorTag    :
              label     : "Color Tag:"
              name      : "colorTag"
          buttons       :
            add         :
              title     : "Add Rule"
              style     : "modal-clean-green"
            export      :
              title     : "Export"
              style     : "modal-clean-gray"
            import      :
              title     : "Import"
              style     : "modal-clean-gray"
            cancel      :
              title     : "Cancel"
              style     : "modal-cancel"
              callback  : =>
                @destroy()
    super options

  viewAppended : ->
    log @
