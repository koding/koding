class CreateStackModal extends KDModalViewWithForms

  constructor: (options = {}, data) ->

    options.overlay           = yes
    options.width             = 720
    options.cssClass          = "clone-stack-modal"
    options.title             = "Create a new stack"
    options.cssClass          = "create-stack"
    options.content           = ""
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
              style           : "modal-clean-green"
              type            : "submit"
              loader          :
                color         : '#eee'
              callback        : =>
                form          = @modalTabs.forms.CreateStackForm
                form.once "FormValidationFailed", =>
                  @modalTabs.forms.CreateStackForm.buttons.create.hideLoader()
            cancel            :
              title           : "Cancel"
              style           : "modal-cancel"
              callback        : -> @destroy()
          fields              :
            title             :
              label           : "Stack title"
              type            : "text"
              name            : "title"
              keyup           : =>
                {title, slug} = @modalTabs.forms.CreateStackForm.inputs
                slug.setValue KD.utils.slugify title.getValue()
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
      slug        : KD.utils.slugify slug.getValue()

    @getOptions().callback meta, @
