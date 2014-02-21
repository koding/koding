class OnboardingDashboardView extends CustomViewsDashboardView

  constructor: (options = {}, data) ->

    options.cssClass = "onboarding-view custom-views"
    options.viewType = "ONBOARDING"

    super options, data

    @addNewButton  = new KDButtonView
      title        : "ADD NEW GROUP"
      cssClass     : "add-new solid green medium"
      callback     : =>
        @setClass  "form-visible"
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
