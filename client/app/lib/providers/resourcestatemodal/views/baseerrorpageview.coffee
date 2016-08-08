kd = require 'kd'
JView = require 'app/jview'

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

    title = if isSingleError
    then 'You got an error:'
    else 'You got some errors:'

    content = if isSingleError
    then "<p>#{errs.first}</p>"
    else "<ul>#{(errs.map (err) -> "<li>#{err}</li>").join ''}</ul>"

    @errorContent.updatePartial """
      <span class='error-title'>#{title}</span>
      #{content}
    """


  onPageDidShow: ->

    # it needs to update container height if it can't be set fixed in css.
    # otherwise, custom scroll doesn't work properly
    container = @getDomElement().find '.main'
    container.css 'height', container.height()
