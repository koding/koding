class KDImageUploadView extends KDFileUploadView

  associateForm:(form)->
    options = @getOptions()
    form.addCustomData options.fieldName, []
    @registerListener
      KDEventTypes  : 'ImageWasResampled'
      listener      : @
      callback      : (pubInst, {name, img, index})=>
        form.addCustomData "#{options.fieldName}.#{index}.#{name}", img.data

    @listController.on 'UnregisteringItem', ({view, index})=>
      form.removeCustomData "#{options.fieldName}.#{index}"

  constructor:(options={})->
    options.actions or= []
    options.allowedTypes or= ['image/jpeg','image/gif','image/png']
    options.fieldName or= 'images'
    super
    @count = 0

  fileReadComplete:(pubInst,{file, progressEvent})->
    options = @getOptions()
    unless file.type in options.allowedTypes
      new KDNotificationView
        title     : 'Not an image!'
        duration  : 1500
    else
      index = @count++
      file.data = progressEvent.target.result
      if @putFileInQueue file
        for own name, action of options.actions
          do (name, action, index)=>
            img = new KDImage(file.data)
            img.processAll action, =>
              @propagateEvent KDEventType: 'ImageWasResampled', {name, img, index}

class KDImageUploadSingleView extends KDFileUploadSingleView

  associateForm:(form)->
    options = @getOptions()
    form.addCustomData options.fieldName, []
    @registerListener
      KDEventTypes  : 'ImageWasResampled'
      listener      : @
      callback      : (pubInst, {name, img, index})=>
        form.addCustomData "#{options.fieldName}.#{index}.#{name}", img.data

    @listController.on 'UnregisteringItem', ({view, index})=>
      form.removeCustomData "#{options.fieldName}.#{index}"

  constructor:(options={})->
    options.actions or= []
    options.allowedTypes or= ['image/jpeg','image/gif','image/png']
    options.fieldName or= 'images'
    super
    @count = 0

  fileReadComplete:(pubInst,{file, progressEvent})->
    options = @getOptions()
    unless file.type in options.allowedTypes
      new KDNotificationView
        title     : 'Not an image!'
        duration  : 1500
    else
      index = @count++
      file.data = progressEvent.target.result
      if @putFileInQueue file
        for own name, action of options.actions
          do (name, action, index)=>
            img = new KDImage(file.data)
            img.processAll action, =>
              @propagateEvent KDEventType: 'ImageWasResampled', {name, img, index}
