class CustomViewsDashboardView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "custom-views-dashboard", options.cssClass

    super options, data

    {cssClass, title} = options

    @title        = new KDCustomHTMLView
      tagName     : "h3"
      cssClass    : cssClass
      partial     : title

    @addNewButton = new KDButtonView
      iconOnly    : yes
      cssClass    : "add-new"
      callback    : => @addNew()

    @noViewLabel  = new KDCustomHTMLView
      tagName     : "p"
      cssClass    : "no-view"
      partial     : "Currently there is no view for this section. Why don't you add new one?"

    @loader       = new KDLoaderView
      cssClass    : "loader"
      showLoader  : yes
      size        :
        width     : 32

    @container    = new KDCustomHTMLView
      cssClass    : "views"

    @noViewLabel.hide()
    @fetchViews()

    @bindEventHandlers()

  bindEventHandlers: ->
    @on "NewViewAdded", =>
      @addNewView.destroy()
      @addNewButton.show()
      @reloadViews()

    @on "ViewDeleted", (customView) ->
      @customViews.splice @customViews.indexOf(customView), 1
      if @customViews.length is 0
        @noViewLabel.show()

    @on "ViewEditRequested", (viewData) =>
      @addNew viewData

    @on "AddingNewViewCancelled", =>
      @reloadViews()
      @addNewButton.show()

  addNew: (data) ->
    customView.hide() for customView in @customViews
    @noViewLabel.hide()
    @addNewButton.hide()

    appManager = KD.singleton "appManager"
    appManager.require "Teamwork", (app) =>
      config     =
        delegate : this
        viewType : @getOption "viewType"

      @addSubView @addNewView = new AddNewCustomViewForm config, data

  reloadViews: ->
    page.destroy() for page in @customViews
    @loader.show()
    @fetchViews()

  fetchViews: ->
    query        = { partialType: @getOption "viewType" }
    @customViews = []

    KD.remote.api.JCustomPartials.some query, {}, (err, customViews) =>
      @loader.hide()
      return @noViewLabel.show()  if err or not customViews.length

      @createList customViews

  createList: (customViews) ->
    viewClass = @getOption("itemClass") or CustomViewItem
    for customView in customViews
      customViewItem = new viewClass { delegate: this }, customView
      @customViews.push customViewItem
      @container.addSubView customViewItem

  pistachio: ->
    """
      {{> @title}}
      {{> @addNewButton}}
      {{> @loader}}
      {{> @noViewLabel}}
      {{> @container}}
    """
