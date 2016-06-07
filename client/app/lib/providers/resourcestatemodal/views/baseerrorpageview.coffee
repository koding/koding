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


  setErrors: (errs) ->

    isSingleError = errs.length is 1

    title = if isSingleError
    then 'You got an error:'
    else 'You got some errors:'

    content = if isSingleError
    then "<p>#{errs.first}</p>"
    else "<ul>#{(errs.map (err) -> "<li>#{err}</li>").join ''}</ul>"

    @errorContent.updatePartial "<span class='error-title'>#{title}</span>#{content}"
