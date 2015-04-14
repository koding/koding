kd                  = require 'kd'
KDView              = kd.View
KDHeaderView        = kd.HeaderView
KDButtonView        = kd.ButtonView
KDCustomHTMLView    = kd.CustomHTMLView
KDHitEnterInputView = kd.HitEnterInputView


module.exports = class MachineSettingsCommonView extends KDView


  constructor: (options = {}, data) ->

    options.header                or= ''
    options.addButtonTitle        or= 'ADD'
    options.addButtonCssClass     or= ''
    options.headerAddButtonTitle  or= 'ADD NEW'

    super options, data


    @addSubView header = new KDHeaderView
      title : options.header

    header.addSubView @headerAddNewButton = new KDButtonView
      title    : options.headerAddButtonTitle
      cssClass : "solid green compact add-button #{options.addButtonCssClass}"
      callback : @bound 'showAddView'


    @createAddView()


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

    wrapper.addSubView new KDButtonView
      cssClass : 'solid green compact add'
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
