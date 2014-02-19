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
      title     : "Home Pages"
      viewType  : "HOME"
      cssClass  : "home-pages"
      itemClass : HomePageCustomViewItem

    @widgets    = new CustomViewsDashboardView
      title     : "Widgets"
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
      {{> @homePages}}
      {{> @widgets}}
    """