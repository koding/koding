class Resource
  
  {GridStore} = mongodb
  
  {ObjectId, Model, JsPath, secure, daisy} = require 'bongo'
  
  {db} = Model.getClient()
  
  @storeImages = secure (client, images, callback)->
    {connection:{delegate}} = client
    queue = []
    filenames = []
    images.forEach (img, i) ->
      storeImages = Object.keys(img).map (size)->
        [header, data] = img[size].split ','
        content_type = header.split(';')[0].split(':')[1]
        data = Buffer(data, 'base64')
        -> Resource.put data, {
          content_type
          metadata      :
            uploadedBy  : delegate.profile.nickname
        }, (err, filename)->
          JsPath.setAt(filenames, "#{i}.#{size}", filename)
          queue.next()
      queue.push storeImages...
    queue.push ->
      callback null, filenames
    daisy queue
  
  @createFilename =(options)-> new ObjectId + '.png'
  
  @put =(data, options, callback)->
    [callback, options] = [options, callback] unless callback
    filename = @createFilename()
    gs = new GridStore db, filename, 'w', options
    gs.open (err)->
      if err
        callback err, null, 500
      else
        gs.write data, (err)->
          gs.close ->
            if err
              callback err, null, 500
            else
              callback null, filename, 200

  @get =(filename, callback)->
    GridStore.exist db, filename, (err, exists)->
      unless exists
        callback new Error('File not found'), null, null, 404
      else
        gs = new GridStore db, filename, 'r'
        gs.open (err)->
          if err
            gs.close -> callback err, null, null, 500
          else gs.read (err, data)->
            gs.close ->
              if err
                callback err, null, null, 500
              else
                callback null, gs, data, 200