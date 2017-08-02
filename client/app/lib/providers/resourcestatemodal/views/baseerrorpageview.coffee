kd = require 'kd'
_  = require 'lodash'


module.exports = class BaseErrorPageView extends kd.View

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
      """

    errorPartial = if isSingleError
    then _.escape errs.first
    else (errs.map (err) -> "<li>#{_.escape err}</li>").join ''
    @errorContent.addSubView new kd.CustomHTMLView
      tagName  : if isSingleError then 'pre' else 'ul'
      partial  : errorPartial

    kd.utils.defer =>
      @errorContainer.wrapper.scrollToBottom()

  # Defer is required here since onPageDidShow is getting called in
  # the same call stack before it's ready in the DOM and it causes
  # issues in the following call ~ GG
  onPageDidShow: -> kd.utils.defer =>
    # it needs to update container height if it can't be set fixed in css.
    # otherwise, custom scroll doesn't work properly
    container = @getDomElement().find '.main'
    container.css 'height', container.height() or 400


  pistachio: -> 'Extend this page to show error modal here'
