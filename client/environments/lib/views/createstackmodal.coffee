kd = require 'kd'
KDModalViewWithForms = kd.ModalViewWithForms
module.exports = class CreateStackModal extends KDModalViewWithForms

  constructor: (options = {}, data) ->

    options.cssClass          = kd.utils.curry "create-stack", options.cssClass
    options.title           or= "Create a new stack"
    options.content         or= ""
    options.overlay           = yes
    options.width             = 720
    options.height            = "auto"
    options.tabs              =
      forms                   :
        CreateStackForm       :
          callback            : @bound "handleSubmit"
          buttons             :
            create            :
              title           : "Create"
              style           : "solid green medium"
              type            : "submit"
              loader          :
                color         : '#eee'
              callback        : =>
                form          = @modalTabs.forms.CreateStackForm
                form.once "FormValidationFailed", =>
                  @modalTabs.forms.CreateStackForm.buttons.create.hideLoader()
            cancel            :
              title           : "Cancel"
              style           : "solid light-gray medium"
              callback        : => @destroy()
          fields              :
            title             :
              label           : "Stack title"
              type            : "text"
              name            : "title"
              keyup           : =>
                {title, slug} = @modalTabs.forms.CreateStackForm.inputs
                slug.setValue kd.utils.slugify title.getValue()
              validate        :
                rules         :
                  required    : yes
                messages      :
                  required    : "Stack title cannot be blank."
            slug              :
              label           : "Domain prefix"
              type            : "text"
              name            : "slug"
              validate        :
                rules         :
                  required    : yes
                messages      :
                  required    : "Domain prefix cannot be blank"

    super options, data

  handleSubmit: ->
    {title, slug} = @modalTabs.forms.CreateStackForm.inputs
    meta          =
      title       : title.getValue()
      slug        : kd.utils.slugify slug.getValue()

    @getOptions().callback meta, @
