class AddNewHomePageView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "add-new-view"

    super options, data

    @input        = new KDInputView
      cssClass    : "page-name"
      type        : "input"
      defaultValue: @getData()?.name or ""

    @editor       = new EditorPane
      cssClass    : "editor-container"
      content     : @getData()?.partial or ""
      size        :
        width     : 876
        height    : 400

    @cancelButton = new KDButtonView
      title       : "CANCEL"
      cssClass    : "solid red"
      callback    : =>
        @destroy()
        @getDelegate().emit "AddingNewHomePageCancelled"

    @saveButton   = new KDButtonView
      title       : "SAVE"
      cssClass    : "solid green"
      callback    : @bound "addNew"

  addNew: ->
    isUpdate       = @getData()
    data           =
      name         : @input.getValue()
      partial      : @editor.getValue()
      partialType  : "HOME"
      isActive     : no
      viewInstance : ""

    # TODO: fatihacet - DRY callbacks
    if isUpdate
      @getData().update data, (err, customPartial) =>
        return warn err  if err
        @getDelegate().emit "NewHomePageAdded", customPartial
    else
      KD.remote.api.JCustomPartials.create data, (err, customPartial) =>
        return warn err  if err
        @getDelegate().emit "NewHomePageAdded", customPartial

  pistachio: ->
    """
      <p>Name:</p>
      {{> @input}}
      <p>Code:</p>
      {{> @editor}}
      <div class="button-container">
        {{> @cancelButton}}
        {{> @saveButton}}
      </div>
    """


class HomePagesDashboardView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "home-pages-dashboard"

    super options, data

    @addNewButton = new KDButtonView
      title       : "ADD NEW"
      cssClass    : "solid green"
      callback    : => @addNew()

    @noPageLabel  = new KDCustomHTMLView
      tagName     : "p"
      cssClass    : "no-page"
      partial     : "Currently there is no home page. Why don't you add new one?"

    @loader       = new KDLoaderView
      cssClass    : "home-pages-loader"
      showLoader  : yes
      size        :
        width     : 32

    @container    = new KDCustomHTMLView
      cssClass    : "home-page-items"

    @noPageLabel.hide()
    @fetchHomePages()

    @bindEventHandlers()

  bindEventHandlers: ->
    @on "NewHomePageAdded", =>
      @addNewHomePageView.destroy()
      @addNewButton.show()
      @reloadViews()

    @on "HomePageDeleted", (homePage) ->
      @homePages.splice @homePages.indexOf(homePage), 1
      if @homePages.length is 0
        @noPageLabel.show()

    @on "HomePageEditRequested", (homePageData) =>
      @addNew homePageData

    @on "ChangeHomePageState", (homePageData) =>
      query     = { isActive: yes }
      for homePage in @homePages when homePage.getData().isActive is yes
        oldActive = homePage

      activate  = =>
        homePageData.update { isActive: !homePageData.isActive }, (err, res) =>
          return warn err  if err
          @reloadViews()

      if oldActive
        oldActive.getData().update { isActive: no }, (err, res) =>
          return warn err  if err
          activate()
      else
        activate()


    @on "AddingNewHomePageCancelled", =>
      page.show() for page in @homePages
      @addNewButton.show()

  addNew: (data) ->
    homePage.hide() for homePage in @homePages
    @noPageLabel.hide()
    @addNewButton.hide()

    appManager = KD.singleton "appManager"
    appManager.require "Teamwork", (app) =>
      @addNewHomePageView = new AddNewHomePageView { delegate: this }, data

      @addSubView @addNewHomePageView

  reloadViews: ->
    page.destroy() for page in @homePages
    @loader.show()
    @fetchHomePages()

  fetchHomePages: ->
    query = { partialType: "HOME" }
    @homePages = []
    KD.remote.api.JCustomPartials.some query, {}, (err, homePages) =>
      @loader.hide()
      return @noPageLabel.show()  if err or not homePages.length

      @createList homePages

  createList: (homePages) ->
    for homePage in homePages
      pageItem = new HomePageItem { delegate: this }, homePage
      @homePages.push pageItem
      @container.addSubView pageItem

  pistachio: ->
    """
      <div class="button-container">
        {{> @addNewButton}}
      </div>
      {{> @loader}}
      {{> @noPageLabel}}
      {{> @container}}
    """

class HomePageItem extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "home-page-item"

    super options, data

    @previewButton = new KDButtonView
      title        : "Preview"
      cssClass     : "preview-button solid gray"
      iconClass    : "preview"
      icon         : yes
      callback     : ->
        new KDNotificationView
          title    : "Coming Soon!"

    @deleteButton  = new KDButtonView
      title        : "Delete"
      cssClass     : "delete-button solid red"
      iconClass    : "delete"
      icon         : yes
      callback     : @bound "delete"

    @editButton    = new KDButtonView
      title        : "Edit"
      cssClass     : "edit-button solid green"
      iconClass    : "edit"
      icon         : yes
      callback     : @bound "edit"

    @activateButton = new KDButtonView
      title        : if @getData().isActive then "Deactivate" else "Activate"
      cssClass     : "activate solid green"
      iconClass    : "activate"
      icon         : yes
      callback     : @bound "updateState"

  updateState: ->
    @getDelegate().emit "ChangeHomePageState", @getData()

  edit: ->
    @getDelegate().emit "HomePageEditRequested", @getData()

  delete: ->
    homePageData = @getData()
    homePageData.remove (err, res) =>
      return warn err  if err
      @getDelegate().emit "HomePageDeleted", homePageData
      @destroy()

  pistachio: ->
    data = @getData()
    """
      <p>#{data.name}</p>
      <div class="button-container">
        {{> @activateButton}}
        {{> @deleteButton}}
        {{> @previewButton}}
        {{> @editButton}}
      </div>
    """
