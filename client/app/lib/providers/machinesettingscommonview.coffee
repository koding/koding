kd                   = require 'kd'
KDView               = kd.View
KDHeaderView         = kd.HeaderView
KDButtonView         = kd.ButtonView
KDListItemView       = kd.ListItemView
KDCustomHTMLView     = kd.CustomHTMLView
KDHitEnterInputView  = kd.HitEnterInputView
KDListViewController = kd.ListViewController

module.exports = class MachineSettingsCommonView extends KDView


  constructor: (options = {}, data) ->

    options.headerTitle           or= ''
    options.addButtonTitle        or= 'ADD'
    options.addButtonCssClass     or= ''
    options.listViewItemClass     or= KDListItemView
    options.headerAddButtonTitle  or= 'ADD NEW'

    super options, data

    @machine = @getData()

    @createHeader()
    @createAddView()
    @createListView()
    @initList()


  createHeader: ->

    { headerTitle, headerAddButtonTitle, addButtonCssClass } = @getOptions()

    @addSubView header = new KDHeaderView title: headerTitle

    header.addSubView @headerAddNewButton = new KDButtonView
      title    : headerAddButtonTitle
      cssClass : "solid green compact add-button #{addButtonCssClass}"
      callback : @bound 'showAddView'


  createAddView: ->

    @addViewContainer = new KDCustomHTMLView cssClass: 'add-view hidden'

    @createAddInput()
    @createAddNewViewButtons()

    @addSubView @addViewContainer


  createAddInput: ->

    @addViewContainer.addSubView @addInputView = new KDHitEnterInputView
      type       : 'text'
      attributes : spellcheck: no
      callback   : @bound 'handleAddNew'


  createAddNewViewButtons: ->

    wrapper = new KDCustomHTMLView cssClass: 'buttons'

    wrapper.addSubView @addNewButton = new KDButtonView
      cssClass : 'solid green compact add'
      loader   : yes
      title    : @getOptions().addButtonTitle
      callback : @bound 'handleAddNew'

    wrapper.addSubView new KDCustomHTMLView
      tagName  : 'span'
      partial  : 'cancel'
      cssClass : 'cancel'
      click    : @bound 'hideAddView'

    @addViewContainer.addSubView wrapper


  showAddView: ->

    @headerAddNewButton.hide()
    @addViewContainer.show()


  hideAddView: ->

    @headerAddNewButton.show()
    @addViewContainer.hide()


  handleAddNew: ->

    kd.warn 'unhandled method'


  createListView: ->

    @listController  = new KDListViewController
      startWithLazyLoader: yes
      lazyLoaderOptions  :
        spinnerOptions   :
          size           : width: 28
      viewOptions        :
        type             : 'domain'
        wrapper          : yes
        itemClass        : @getOptions().listViewItemClass
        itemOptions      :
          machineId      : @machine._id

    @addSubView @listController.getView()


  initList: ->

    kd.warn 'unhandled method'
