kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDLoaderView = kd.LoaderView
AddNewCustomViewForm = require './addnewcustomviewform'
CustomViewItem = require './customviewitem'
JView = require 'app/jview'
CustomPartialHelpers = require 'dashboard/custompartialhelpers'


module.exports = class CustomViewsDashboardView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "custom-views-dashboard", options.cssClass

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

    @customViews = []
    @fetchViews()


  hideViews: ->

    customView.hide() for customView in @customViews
    @noViewLabel.hide()
    @addNewButton.hide()


  showViews: ->

    customView.show() for customView in @customViews
    @addNewButton.show()
    @showNoViewLabelIfNeeded()


  showNoViewLabelIfNeeded: ->

    @noViewLabel.show()  if @customViews.length is 0


  addNew: (data) ->

    @hideViews()
    @setClass "edit-mode"
    config     =
      delegate : this
      viewType : @getOption "viewType"

    FormClass = @getOption("formClass") or AddNewCustomViewForm
    @addSubView @addNewView = new FormClass config, data
    @addNewView.on 'NewViewAdded',     @bound 'handleNewViewAdded'
    @addNewView.on 'NewViewCancelled', @bound 'handleNewViewCancelled'


  reloadViews: ->

    page.destroy() for page in @customViews
    @loader.show()
    @fetchViews()


  fetchViews: ->

    query = { partialType: @getOption "viewType" }

    CustomPartialHelpers.getPartials query, (err, customViews) =>
      @loader.hide()
      return @noViewLabel.show()  if err or not customViews.length

      @createList customViews


  createList: (customViews) ->

    viewClass = @getOption("itemClass") or CustomViewItem
    for customView in customViews
      customViewItem = new viewClass { delegate: this }, customView
      customViewItem.on 'ViewDeleted',       @bound 'handleViewDeleted'
      customViewItem.on 'ViewEditRequested', @bound 'handleViewEditRequested'

      @customViews.push customViewItem
      @container.addSubView customViewItem


  handleNewViewAdded: ->

    @unsetClass "edit-mode"
    @addNewView.destroy()
    @addNewButton.show()
    @reloadViews()


  handleViewDeleted: (customView) ->

    @customViews.splice @customViews.indexOf(customView), 1
    @showNoViewLabelIfNeeded()


  handleViewEditRequested: (viewData) -> @addNew viewData


  handleNewViewCancelled: ->

    @unsetClass "edit-mode"
    @reloadViews()
    @addNewButton.show()


  pistachio: ->

    """
      <div class="clearfix">
        {{> @title}}
        {{> @addNewButton}}
      </div>
      <div class="clearfix">
        {{> @loader}}
        {{> @noViewLabel}}
        {{> @container}}
      </div>
    """


