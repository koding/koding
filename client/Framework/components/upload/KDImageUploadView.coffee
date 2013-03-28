class KDImageUploadView extends KDFileUploadView

  associateForm:(form)->
    options = @getOptions()
    form.addCustomData options.fieldName, []
    @on 'ImageWasResampled', ({name, img, index})=>
      shouldRemoveOld = @getOptions().onlyOne and
                        @previousPath? and
                        @previousPath.indexOf('.'+index) < 0

      form.removeCustomData @previousPath  if shouldRemoveOld

      form.addCustomData "#{options.fieldName}.#{index}.#{name}", img.data
      @previousPath = "#{options.fieldName}.#{index}"

    @listController.on 'UnregisteringItem', ({view, index})=>
      form.removeCustomData "#{options.fieldName}.#{index}"

  constructor:(options={})->
    options.actions       ?= []
    options.allowedTypes  ?= ['image/jpeg','image/gif','image/png']
    options.fieldName     ?= 'images'

    super
    @count = 0

  fileReadComplete:(file, event)->
    @emit 'fileReadComplete', event
    options = @getOptions()
    unless file.type in options.allowedTypes
      new KDNotificationView
        title     : 'Not an image!'
        duration  : 1500
    else
      index = @count++
      file.data = event.target.result
      if @putFileInQueue file
        for own name, action of options.actions
          do (name, action, index)=>
            img = new KDImage file.data
            img.processAll action, =>
              @emit 'ImageWasResampled', {name, img, index}

class KDImageUploadSingleView extends KDImageUploadView
  constructor:(options, data)->
    options.onlyOne = yes
    super