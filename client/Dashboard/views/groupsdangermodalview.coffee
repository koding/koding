
class GroupsDangerModalView extends KDModalViewWithForms

  constructor:(options = {}, data)->

    options.action or= 'Danger Zone'
    options.longAction or= 'do some danger action'
    options.callback ?= -> log "#{options.action} performed"

    options.title or= options.action
    options.content or= "<div class='modalformline'><p><strong>Caution:</strong> Are you sure that you want to #{options.longAction}? This cannot be revoked! </p><br><p>Please enter <strong>#{data.slug}</strong> into the field below to continue: </p></div>"
    options.overlay ?= yes
    options.width ?= 500
    options.height ?= 'auto'

    options.tabs ?=
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
                color        : "#444444"
              callback       : -> @showLoader()
            Cancel           :
              style          : 'modal-cancel'
              callback       : (event)=> @destroy()
          fields             :
            groupSlug        :
              itemClass      : KDInputView
              placeholder    : "Enter '#{data.slug}' to confirm..."
              validate       :
                rules        :
                  required   : yes
                  slugCheck  : (input, event) => @checkGroupSlug input, no
                  finalCheck : (input, event) => @checkGroupSlug input
                messages     :
                  required   : 'Please enter group slug'
                events       :
                  required   : 'blur'
                  slugCheck  : 'keyup'
                  finalCheck : 'blur'

    super options, data

  checkGroupSlug:(input, showError=yes)=>

    if input.getValue() is @getData().slug
      input.setValidationResult 'slugCheck', null
      @modalTabs.forms.dangerForm.buttons.confirmButton.enable()
    else
      input.setValidationResult 'slugCheck', 'Sorry, entered value does not match group slug!', showError
