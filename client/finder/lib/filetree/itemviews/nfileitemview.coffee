kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDLoaderView = kd.LoaderView

FSHelper = require 'app/util/fs/fshelper'
Encoder = require 'htmlencode'


module.exports = class NFileItemView extends KDCustomHTMLView

  # loaderRequiredEvents = ['job', 'remove', 'save', 'saveAs']

  constructor: (options = {}, data) ->

    options.tagName   or= 'div'
    options.cssClass  or= 'file'

    super options, data


    @loader = new KDLoaderView
      size          :
        width       : 16
      loaderOptions :
        # color       : @utils.getRandomHex()
        color       : '#71BAA2'
        shape       : 'rect'
        diameter    : 16
        density     : 12
        range       : 1
        speed       : 1
        FPS         : 24

    @icon = new KDCustomHTMLView
      tagName   : 'span'
      cssClass  : 'icon'

    # for eventName in loaderRequiredEvents
    #   fileData.on "fs.#{eventName}.started",  => @showLoader()
    #   fileData.on "fs.#{eventName}.finished", => @hideLoader()

  destroy: ->

    # fileData = @getData()
    # for eventName in loaderRequiredEvents
    #   fileData.off "fs.#{eventName}.started"
    #   fileData.off "fs.#{eventName}.finished"

    super

  decorateItem: ->

    extension = FSHelper.getFileExtension @getData().name
    if extension
      fileType = FSHelper.getFileType extension
      @icon.$().attr 'class', "icon #{extension} #{fileType}"

  render: ->

    super
    @decorateItem()

  mouseDown: -> yes

  viewAppended: ->

    super

    @hideLoader()
    @decorateItem()

  showLoader: ->

    @parent?.isLoading = yes
    @icon.hide()
    @loader.show()

  hideLoader: ->

    @parent?.isLoading = no
    @icon.show()
    @loader.hide()


  pistachio: ->
    data = @getData()
    path = FSHelper.plainPath data.path
    name = Encoder.XSSEncode data.name
    """
      {{> @icon}}
      {{> @loader}}
      <span class='title' title="#{path}">#{name}</span>
      <span class='chevron'></span>
    """
