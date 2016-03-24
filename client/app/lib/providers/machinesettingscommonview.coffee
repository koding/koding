_                    = require 'lodash'
kd                   = require 'kd'
KDView               = kd.View
KDHeaderView         = kd.HeaderView
KDButtonView         = kd.ButtonView
KDListItemView       = kd.ListItemView
KDCustomHTMLView     = kd.CustomHTMLView
KDHitEnterInputView  = kd.HitEnterInputView
KodingListController = require 'app/kodinglist/kodinglistcontroller'

module.exports = class MachineSettingsCommonView extends KDView

  constructor: (options = {}, data) ->

    options.headerTitle           or= ''
    options.addButtonTitle        or= 'ADD'
    options.addButtonCssClass     or= ''
    options.listViewItemClass     or= KDListItemView
    options.noItemFoundWidget     or= new KDView
    options.listViewItemOptions   or= {}
    options.headerAddButtonTitle  or= 'ADD NEW'
    options.loaderOnHeaderButton   ?= no

    super options, data

    @machine = @getData()

    @createElements()


  createElements: ->

    @createHeader()
    @createAddView()
    @createListView()


  createHeader: ->

    { headerTitle, headerAddButtonTitle
      addButtonCssClass, loaderOnHeaderButton } = @getOptions()

    @addSubView header = new KDHeaderView { title: headerTitle }

    header.addSubView @headerAddNewButton = new KDButtonView
      title    : headerAddButtonTitle
      cssClass : "solid green small add-button #{addButtonCssClass}"
      loader   : loaderOnHeaderButton
      callback : @bound 'showAddView'

    @addSubView @notificationView = new KDCustomHTMLView
      cssClass : 'notification hidden'


  createAddView: ->

    @addViewContainer = new KDCustomHTMLView { cssClass: 'add-view hidden' }

    @createAddInput()
    @createAddNewViewButtons()

    @addSubView @addViewContainer


  createAddInput: ->

    @addViewContainer.addSubView @addInputView = new KDHitEnterInputView
      type       : 'text'
      attributes : { spellcheck: no }
      callback   : @bound 'handleAddNew'


  createAddNewViewButtons: ->

    wrapper = new KDCustomHTMLView { cssClass: 'buttons' }

    wrapper.addSubView @addNewButton = new KDButtonView
      cssClass : 'solid green small add'
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
    kd.utils.defer @addInputView.bound 'setFocus'


  hideAddView: ->

    @headerAddNewButton.show()
    @addViewContainer.hide()
    @addInputView.setValue ''


  handleAddNew: ->

    kd.warn 'handleAddNew method needs to be implemented in subclass'


  createListView: ->

    itemOptions = @getOptions().listViewItemOptions
    itemOptions.machineId = @machine._id

    { listViewItemClass, noItemFoundWidget } = @getOptions()

    listViewOptions = @getOption('listViewOptions') or {}

    options = _.extend listViewOptions,
      viewOptions           :
        wrapper             : yes
        itemOptions         : itemOptions
      itemClass             : listViewItemClass
      noItemFoundWidget     : noItemFoundWidget

    @listController  = new KodingListController options

    @addSubView @listController.getView()


  initList: ->

    kd.warn 'initList method needs to be implemented in subclass'


  showNotification: (err, type = 'error') ->

    view    = @notificationView
    message = err

    if _.isObject message
      if err.code is '107'
        message = 'The domain could not be added as the VM is locked by another update process. Please try again in a few minutes.'
      else
        message = err.message

    view.unsetClass 'success error warning'
    view.setClass type
    view.updatePartial message
    view.show()

    if type is 'error' or type is 'warning'
      kd.warn err
