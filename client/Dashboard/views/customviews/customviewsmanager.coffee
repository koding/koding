class CustomViewsManager extends JView

  cookieName = "custom-partials-preview-mode"

  constructor: (options = {}, data) ->

    options.cssClass = "custom-views"

    super options, data

    @previewButton = new KDButtonView
      title        : "PREVIEW"
      cssClass     : "solid green preview"
      callback     : @bound "togglePreview"

    if $.cookie cookieName
      @previewButton.setTitle   "CANCEL PREVIEW"
      @previewButton.unsetClass "green"

    @homePages  = new CustomViewsDashboardView
      viewType  : "HOME"
      cssClass  : "home-pages"
      itemClass : HomePageCustomViewItem

    @widgets    = new CustomViewsDashboardView
      viewType  : "WIDGET"
      cssClass  : "widgets"
      itemClass : WidgetCustomViewItem

  togglePreview: ->
    isPreview = $.cookie cookieName

    if isPreview
      $.cookie cookieName, no
      @previewButton.setTitle "PREVIEW"
      @previewButton.setClass "green"
    else
      $.cookie cookieName, yes
      @previewButton.setTitle   "CANCEL PREVIEW"
      @previewButton.unsetClass "green"

  pistachio: ->
    """
      <div class="button-container">
        {{> @previewButton}}
      </div>
      <h3 class="home-pages">Home Pages</h3>
      {{> @homePages}}
      <h3>Widgets</h3>
      {{> @widgets}}
    """