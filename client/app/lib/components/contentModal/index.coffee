_ = require 'lodash'
kd = require 'kd'

require './styl/contentModal.styl'


module.exports = class ContentModal extends kd.ModalView

  constructor: (options = {}, data) ->

    contentAttrs = ['title', 'content', 'cssClass', 'buttons']

    modalOptions = _.omit options, contentAttrs
    @contentOptions = _.pick options, contentAttrs

    modalOptions.cssClass = 'ContentModal'
    modalOptions.width or= 500

    modalOptions.overlayOptions =
      isRemovable : no
      cssClass    : 'content-overlay'

    super modalOptions, data

    @createHeader()
    @createBody()
    @createFooter()

  # commented function in kd.ModalView class
  keyup: (e) ->
    @cancel() if e.which is 27

  createHeader: ->

    { title, cssClass } = @contentOptions
    @setClass cssClass


    @addSubView header = new kd.CustomHTMLView
      tagName : 'header'
      partial : "<h1>#{title}</h1>"


  createBody: ->

    { content } = @contentOptions

    { tabs } = @getOptions()

    @addSubView @main = new kd.CustomHTMLView
      tagName : 'main'
      cssClass : 'main-container'

    if content
      if typeof content is 'string'
        @main.setPartial content
      else
        @main.addSubView content

    if tabs
      @main.addSubView @modalTabs = new kd.TabViewWithForms tabs
      @setClass 'with-form'
      @main.setClass 'tabview'


  createFooter: ->

    { buttons } = @contentOptions

    return  unless buttons

    @addSubView @footer = new kd.CustomHTMLView
      tagName : 'footer'

    Object.keys(buttons).forEach (key) =>
      button = new kd.ButtonView buttons[key]
      if buttons[key].title is 'Cancel' or buttons[key].title is 'No'
        button.setClass 'cancel'
      else
        button.setAttribute 'testpath', 'proceed'
      @footer.addSubView @["button_#{key}"] = button
