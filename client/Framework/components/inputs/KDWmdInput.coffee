#####
# WMD input forked from stackoverflow's clone
#####

class KDWmdInput extends KDInputView
  constructor:(options,data)->
    options = options ? {}
    options.type = "textarea"
    options.preview = options.preview ? no
    super options,data
    @setClass "monospace"

  setWMD:()->  
    preview = @getOptions().preview
    @getDomElement().wmd
      preview : preview
    if preview
      @getDomElement().after "<h3 class='wmd-preview-title'>Preview:</h3>"