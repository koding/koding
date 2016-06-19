kd                    = require 'kd'

module.exports = class NewModalView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass ?= 'new-modal'

    super options, data

    @createHeader()
    @createBody()
    @createFooter()


  createHeader: ->

    { title, cssClass } = @getOptions()

    @setClass cssClass


    @addSubView header = new kd.CustomHTMLView
      tagName : 'header'
      partial : "<h1>#{title}</h1>"


  createBody: ->

    { content } = @getOptions()

    @addSubView main = new kd.CustomHTMLView
      tagName : 'main'
      partial : content


  createFooter: ->

    { buttons } = @getOptions()
    console.log {buttons}

    if buttons
      @addSubView @footer = new kd.CustomHTMLView
        tagName : 'footer'

      Object.keys(buttons).forEach (key) =>
        console.log {key}
        console.log buttons[key]
        button = new kd.ButtonView buttons[key]
        if buttons[key].title is 'Cancel' or buttons[key].title is 'No'
          button.setClass 'cancel'
        @footer.addSubView button
