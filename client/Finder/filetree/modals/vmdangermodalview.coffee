class VmDangerModalView extends KDModalViewWithForms

  constructor:(options = {}, data)->

    options.action    or= 'Danger Zone'
    options.title     or= options.action
    options.content   or= "<div class='modalformline'><p><strong>CAUTION! </strong>This will destroy the <strong>#{options.name}</strong> VM including all its data. This action <strong>CANNOT</strong> be undone.</p><br><p>Please enter <strong>#{data}</strong> into the field below to continue: </p></div>"
    options.callback   ?= -> log "#{options.action} performed"
    options.overlay    ?= yes
    options.width      ?= 500
    options.height     ?= 'auto'
    options.tabs       ?=
      forms                  :
        dangerForm           :
          callback           : =>
            callback = => @modalTabs.forms.dangerForm.buttons.confirmButton.hideLoader()
            options.callback callback
          buttons            :
            confirmButton    :
              title          : options.action
              style          : 'modal-clean-red'
              type           : 'submit'
              disabled       : yes
              loader         :
                color        : '#E94835'
              callback       : -> @showLoader()
            Cancel           :
              style          : 'modal-cancel'
              callback       : @bound 'destroy'
          fields             :
            vmSlug           :
              itemClass      : KDInputView
              placeholder    : "Enter '#{data}' to confirm..."
              validate       :
                rules        :
                  required   : yes
                  slugCheck  : (input, event) => @checkVmName input, no
                  finalCheck : (input, event) => @checkVmName input
                messages     :
                  required   : 'Please enter vm name'
                events       :
                  required   : 'blur'
                  slugCheck  : 'keyup'
                  finalCheck : 'blur'

    super

  checkVmName:(input, showError=yes)=>

    if input.getValue() is @getData()
      input.setValidationResult 'slugCheck', null
      @modalTabs.forms.dangerForm.buttons.confirmButton.enable()
    else
      @modalTabs.forms.dangerForm.buttons.confirmButton.disable()
      input.setValidationResult 'slugCheck', 'Sorry, entered value does not match vm name!', showError
