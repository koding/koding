class KDImage
  {round} = Math

  daisy = (args, fn) ->
    setTimeout args.next = ->
      if (f = args.shift()) then !!f(args) or yes else no
    , 0

  @dataURItoBlob = (dataURI) ->
    byteString = atob(dataURI.split(",")[1])
    mimeString = dataURI.split(",")[0].split(":")[1].split(";")[0]
    ab = new ArrayBuffer byteString.length
    ia = new Uint8Array ab

    i = 0
    while i < byteString.length
      ia[i] = byteString.charCodeAt(i)
      i++

    bb = new BlobBuilder
    bb.append ab
    bb.getBlob mimeString


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

  @process 'resample', (data, {scaledWidth, lobesKernel}, callback)->
    #returns a function that calculates lanczos weight
    lanczosCreate = (lobes)->
      return (x)->
        if x > lobes
          return 0
        x *= Math.PI
        if Math.abs(x) < 1e-16
          return 1
        xx = x / lobes
        return Math.sin(x) * Math.sin(xx) / x / xx

    # elem: canvas element, img: image element, sx: scaled width, lobes: kernel radius
    resampler = (resampleCanvas, img, sx, lobes, kallback)=>
      @canvas                 = resampleCanvas
      @canvas.width           = img.width
      @canvas.height          = img.height
      @canvas.style.display   = "none"
      @ctx                    = @canvas.getContext "2d"
      @ctx.drawImage img, 0, 0
      @img                    = img
      @src = @ctx.getImageData 0, 0, img.width, img.height
      @dest =
        width: sx
        height: Math.round(img.height * sx / img.width)
      @dest.data = new Array(@dest.width*@dest.height*3)
      @lanczos = lanczosCreate lobes
      @ratio = img.width / sx
      @rcp_ratio = 2 / @ratio
      @range2 = Math.ceil(@ratio * lobes / 2)
      @cacheLanc = {}
      @center = {}
      @icenter = {}
      setTimeout =>
        @process1(@, 0)
      ,0

      @process1 = (self, u)=>
        self.center.x = (u + 0.5) * self.ratio
        self.icenter.x = Math.floor(self.center.x)
        for v in [0...self.dest.height]
          self.center.y = (v + 0.5) * self.ratio
          self.icenter.y = Math.floor(self.center.y)
          a = r = g = b = 0
          for i in [(self.icenter.x-self.range2)..(self.icenter.x+self.range2)]
            if (i < 0 || i >= self.src.width)
              continue
            f_x = Math.floor(1000 * Math.abs(i - self.center.x))
            if (!self.cacheLanc[f_x])
              self.cacheLanc[f_x] = {}
            for j in [(self.icenter.y-self.range2)..(self.icenter.y+self.range2)]
              if (j < 0 || j >= self.src.height)
                continue
              f_y = Math.floor(1000 * Math.abs(j - self.center.y))
              if (self.cacheLanc[f_x][f_y] == undefined)
                self.cacheLanc[f_x][f_y] = self.lanczos(Math.sqrt(Math.pow(f_x * self.rcp_ratio, 2) + Math.pow(f_y * self.rcp_ratio, 2)) / 1000)
              weight = self.cacheLanc[f_x][f_y]
              if (weight > 0)
                idx = (j * self.src.width + i) * 4
                a += weight
                r += weight * self.src.data[idx]
                g += weight * self.src.data[idx + 1]
                b += weight * self.src.data[idx + 2]
          idx = (v * self.dest.width + u) * 3
          self.dest.data[idx] = r / a
          self.dest.data[idx + 1] = g / a
          self.dest.data[idx + 2] = b / a

        if (++u < self.dest.width)
          setTimeout =>
            self.process1(self, u)
          ,0
        else
          setTimeout =>
            self.process2 self
          ,0

      @process2 = (self)=>
        self.canvas.width = self.dest.width;
        self.canvas.height = self.dest.height;
        self.ctx.drawImage(self.img, 0, 0);
        self.src = self.ctx.getImageData(0, 0, self.dest.width, self.dest.height);
        for i in [0...self.dest.width]
          for j in [0...self.dest.height]
            idx = (j * self.dest.width + i) * 3;
            idx2 = (j * self.dest.width + i) * 4;
            self.src.data[idx2] = self.dest.data[idx];
            self.src.data[idx2 + 1] = self.dest.data[idx + 1];
            self.src.data[idx2 + 2] = self.dest.data[idx + 2];
        self.ctx.putImageData(self.src, 0, 0);
        self.canvas.style.display = "block";
        kallback self

    canvas = document.createElement('canvas')

    resampler canvas, data, scaledWidth, lobesKernel, (res)=>
      callback res.canvas.toDataURL(@format)

  createView:->
    new KDCustomHTMLView
      tagName: 'img'
      attributes:
        src: if 'string' is typeof @data then @data else @data.src