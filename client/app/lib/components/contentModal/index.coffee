_ = require 'lodash'
kd = require 'kd'

module.exports = class ContentModal extends kd.ModalView

  constructor: (options = {}, data) ->

    contentAttrs = ['title', 'content', 'cssClass', 'buttons']

    modalOptions = _.omit options, contentAttrs
    @contentOptions = _.pick options, contentAttrs

    modalOptions.cssClass = 'ContentModal'

    super modalOptions, data

    @createHeader()
    @createBody()
    @createFooter()


  createHeader: ->

    { title, cssClass } = @contentOptions
    @setClass cssClass


    @addSubView header = new kd.CustomHTMLView
      tagName : 'header'
      partial : "<h1>#{title}</h1>"


  createBody: ->

    { content } = @contentOptions

    @addSubView main = new kd.CustomHTMLView
      tagName : 'main'
      partial : content


  createFooter: ->

    { buttons } = @contentOptions

    if buttons
      @addSubView @footer = new kd.CustomHTMLView
        tagName : 'footer'

      Object.keys(buttons).forEach (key) =>
        button = new kd.ButtonView buttons[key]
        if buttons[key].title is 'Cancel' or buttons[key].title is 'No'
          button.setClass 'cancel'
        @footer.addSubView button
