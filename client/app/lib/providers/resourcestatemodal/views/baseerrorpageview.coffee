kd = require 'kd'
JView = require 'app/jview'
copyToClipboard = require 'app/util/copyToClipboard'
getCopyToClipboardShortcut = require 'app/util/getCopyToClipboardShortcut'

module.exports = class BaseErrorPageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @errorContent = new kd.CustomHTMLView
      cssClass : 'error-content'

    @errorContainer = new kd.CustomScrollView
      cssClass : 'error-container'
    @errorContainer.wrapper.addSubView @errorContent

    @on 'PageDidShow', @bound 'onPageDidShow'


  setErrors: (errs) ->

    isSingleError = errs.length is 1

    @errorContent.destroySubViews()

    @errorContent.addSubView new kd.CustomHTMLView
      cssClass : 'error-title'
      partial  : """
        You got #{if isSingleError then 'an error' else 'some errors'}:
        <cite>#{getCopyToClipboardShortcut()}</cite>
      """

    errorPartial = if isSingleError
    then errs.first
    else (errs.map (err) -> "<li>#{err}</li>").join ''
    @errorContent.addSubView new kd.CustomHTMLView
      tagName  : if isSingleError then 'p' else 'ul'
      partial  : errorPartial
      click    : -> copyToClipboard @getElement()


  onPageDidShow: ->

    # it needs to update container height if it can't be set fixed in css.
    # otherwise, custom scroll doesn't work properly
    container = @getDomElement().find '.main'
    container.css 'height', container.height()
