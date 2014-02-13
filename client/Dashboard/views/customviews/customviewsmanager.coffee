class CustomViewsManager extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "custom-views"

    super options, data

    @previewButton = new KDButtonView
      title        : "PREVIEW"
      cssClass     : "solid green preview"
      callback     : ->
        new KDNotificationView
          title    : "Coming Soon!"

    @homePages  = new CustomViewsDashboardView
      viewType  : "HOME"
      cssClass  : "home-pages"
      itemClass : HomePageCustomViewItem

    @widgets    = new CustomViewsDashboardView
      viewType  : "WIDGET"
      cssClass  : "widgets"
      itemClass : WidgetCustomViewItem

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