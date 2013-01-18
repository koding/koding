class KDImage
  {round} = Math

  daisy = (args, fn) ->
    setTimeout args.next = ->
      if (f = args.shift()) then !!f(args) or yes else no
    , 0

  #BlobBuilder and ArrayBuffer are now deprecated, here is an updated version
  #with Blob constructor, #http://stackoverflow.com/a/11954337/462233
  @dataURItoBlob = (dataURI) ->
    binary = atob(dataURI.split(",")[1])
    array = []

    i = 0
    while i < binary.length
      array.push binary.charCodeAt(i)
      i++

    new Blob([new Uint8Array(array)],
      type: "image/png"
    )

  constructor:(@data, @format='image/png')->
    # {@data} = file
    @queue = []

  @process =(action, algorithm)->
    @::[action] = (options, callback)->
      kallback = (@data)=> callback data
      if 'string' is typeof @data
        @load @data, (data)=> algorithm.call @, data, options, kallback
      else
        algorithm.call @, @data, options, kallback

  load:(src, callback)->
    img = new Image
    img.src = src
    img.onload = ->
      callback img

  toBlob:-> KDImage.dataURItoBlob @data

  processAll:(action, callback)->
    img = @
    steps = (process for process, i in action when i % 2 is 0)
    queue = steps.map (process, i)->
      options = action[i*2+1]
      -> img[process] options, queue.next
    queue.push -> callback img
    daisy queue

  @process 'scale', (data, {shortest, width, height}, callback)->
    if shortest?
      if data.width < data.height
        width = shortest
      else
        height = shortest
    width ?= round data.width * height / data.height
    height ?= round data.height * width / data.width
    canvas = document.createElement('canvas')
    canvas.width = width
    canvas.height = height
    canvas.getContext('2d').drawImage(data
      0, 0, data.width, data.height
      0, 0, width, height
    )
    callback canvas.toDataURL(@format)

  @process 'crop', (data, {top, left, width, height}, callback)->
    top ?= round (height - data.height) / 2
    left ?= round (width - data.width) / 2
    canvas = document.createElement('canvas')
    canvas.width = width
    canvas.height = height
    canvas.getContext('2d').drawImage(data
      0, 0, data.width, data.height
      left, top, data.width, data.height
    )
    callback canvas.toDataURL(@format)

  createView:->
    new KDCustomHTMLView
      tagName: 'img'
      attributes:
        src: if 'string' is typeof @data then @data else @data.src
