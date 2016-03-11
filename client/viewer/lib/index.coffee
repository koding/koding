kd               = require 'kd'
KDViewController = kd.ViewController
PreviewerView    = require './previewerview'


module.exports = class ViewerAppController extends KDViewController

  @options = require './options'

  constructor:(options = {}, data)->

    options.view = new PreviewerView
      params     : options.params

    options.appInfo =
      title         : "Preview"
      cssClass      : "ace"

    super options, data


  open:(path)-> @getView().openPath path
