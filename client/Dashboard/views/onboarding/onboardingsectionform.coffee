class OnboardingSectionForm extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    options.cssClass      = "section-form"
    @jCustomPartial       = data
    formData              = data?.partial or {}
    options.fields        =
      name                :
        placeholder       : "Name of your set"
        name              : "name"
        cssClass          : "thin"
        label             : "Name"
        defaultValue      : data?.name or ""
      app                 :
        name              : "app"
        label             : "App"
        cssClass          : "app"
        type              : "hidden"
        nextElement       :
          app             :
            itemClass     : KDSelectBox
            cssClass      : "apps"
            defaultValue  : formData?.app
            selectOptions : [
              { title     : "Activity", value: "Activity" }
              { title     : "Teamwork", value: "Teamwork" }
              { title     : "Ace",      value: "Ace"      }
              { title     : "Terminal", value: "Terminal" }
              { title     : "Apps",     value: "Apps"     }
              { title     : "Bugs",     value: "Bugs"     }
            ]
      visibility          :
        label             : "Show items together"
        itemClass         : KodingSwitch
        defaultValue      : formData?.visibility ? no
      overlay             :
        label             : "Add Overlay"
        itemClass         : KodingSwitch
        defaultValue      : formData?.overlay ? yes

    options.buttons       =
      Save                :
        title             : "SAVE CHANGES"
        style             : "solid green medium fr"
        callback          : @bound "save"
      Cancel              :
        title             : "CANCEL"
        style             : "solid medium fr cancel"
        callback          : @bound "cancel"

    super options, data

  save: ->
    data              =
      partialType     : "ONBOARDING"
      partial         :
        visibility    : @inputs.visibility.getValue()
        overlay       : @inputs.overlay.getValue()
        app           : @inputs.app.getValue()
        items         : @jCustomPartial?.items           or []
      name            : @inputs.name.getValue()          or ""
      viewInstance    : @jCustomPartial?.viewInstance    or ""
      isActive        : @jCustomPartial?.isActive        or no
      isPreview       : @jCustomPartial?.isPreview       or no
      previewInstance : @jCustomPartial?.previewInstance or no

    if @jCustomPartial
      @jCustomPartial.update data, (err, section) =>
        return warn err  if err
        @destroy()
        @getDelegate().emit "NewSectionAdded"
    else
      KD.remote.api.JCustomPartials.create data, (err, section) =>
        return warn err  if err
        @destroy()
        @getDelegate().emit "NewSectionAdded"

  cancel: ->
    @destroy()
    @getDelegate().unsetClass "form-visible"
