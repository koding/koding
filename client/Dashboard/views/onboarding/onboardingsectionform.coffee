class OnboardingSectionForm extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    options.cssClass   = "section-form"

    options.fields     =
      name             :
        placeholder    : "Name of your set"
        name           : "name"
        cssClass       : "thin"
        label          : "Name"
      visibility       :
        label          : "Show items together"
        itemClass      : KodingSwitch
        defaultValue   : no
      overlay          :
        label          : "Add Overlay"
        itemClass      : KodingSwitch
        defaultValue   : no

    options.buttons    =
      Save             :
        title          : "SAVE CHANGES"
        type           : "submit"
        style          : "solid green medium fr"
      Cancel           :
        title          : "CANCEL"
        style          : "solid medium fr cancel"
        callback       : @bound "cancel"


    options.callback   = @bound "addNew"

    super options, data

  addNew: (data) ->
    data              =
      name            : data.name or ""
      partialType     : "ONBOARDING"
      partial         :
        visibility    : data.visibility
        overlay       : data.overlay
        items         : []
      # TODO: Update sets this options to default
      isActive        : no
      viewInstance    : ""
      isPreview       : no
      previewInstance : no

    KD.remote.api.JCustomPartials.create data, (err, section) =>
      return warn err  if err
      @destroy()
      @getDelegate().emit "NewSectionAdded", section

  cancel: ->
    @destroy()
    @getDelegate().unsetClass "form-visible"
