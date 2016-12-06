_ = require 'lodash'
kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
require './styl/uploadbutton.styl'

module.exports = class UploadFileButton extends KDCustomHTMLView
  
  constructor: (options = {}) ->
    
    options.callback or= kd.utils.noop

    super options 
    
    @addSubView button = new kd.ButtonView
      cssClass: 'upload-file-button'
      partial : 'Attach image files by dragging & dropping or <span>selecing them</span>.'
      callback: @bound 'handleFileUpload'
    
    
  handleFileUpload: ->
    
    @getOptions().callback()
