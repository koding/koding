class OnboardingDashboardView extends CustomViewsDashboardView

  constructor: (options = {}, data) ->

    options.cssClass = "onboarding-view custom-views"
    options.viewType = "ONBOARDING"

    super options, data

    @addNewButton  = new KDButtonView
      title        : "ADD NEW SECTION"
      cssClass     : "add-new solid green medium"
      callback     : =>
        @setClass "form-visible"
        @addSubView new OnboardingSectionForm
          delegate : this

    @on "NewSectionAdded", =>
      @unsetClass "form-visible"
      @container.destroySubViews()
      @reloadViews()

  createList: (sections) ->
    @noViewLabel.hide()
    for section in sections
      view = new OnboardingItemView
        delegate    : this
        title       : section.name
        cssClass    : "onboarding-items"
        formClass   : OnboardingAddNewForm
      , section

      @customViews.push view
      @container.addSubView view

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
