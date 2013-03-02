
class KDMultipartUploader extends KDEventEmitter
  boundary = "gc0p4Jq0M2Yt08jU534c0p"

  constructor: ({@url, @file, id}) ->
    throw new Error "FileReader API not found!" unless "FileReader" of window
    super()
    @id = id ? 'file'

  makeMultipartItem: (name, value) ->
    "
--#{boundary}\r\n
Content-Disposition: form-data; name=\"#{name}\"\r\n\r\n
#{value}\r\n
"

  serializedToMultipart: (list) ->
    (@makeMultipartItem i.name, i.value for i in list).join("")

  fileToMultipart: (callback) ->
    # {files, id} = @input
    fr = new FileReader
    return callback "" unless @file

    wrapFile = (fileData) =>
      "
--#{boundary}\r\n
Content-Disposition: form-data; name=\"#{@id}\"; filename=\"#{@file.name}\"\r\n
Content-Type: #{@file.type}\r\n\r\n
#{fileData}\r\n
--#{boundary}--\r\n
"
    fr.onload = (event) =>
      return unless event.loaded is event.total
      @emit 'FileReadComplete', event
      callback wrapFile event.currentTarget.result
    fr.readAsBinaryString @file

  send: ->
    fr = new FileReader
    xhr = new XMLHttpRequest
    body = ""

    xhr.open "POST", @url, true
    xhr.setRequestHeader "Content-Type",
      "multipart/form-data; boundary=#{boundary}"
    xhr.onreadystatechange = =>
      return unless xhr.readyState is 4
      if xhr.status >= 200 and xhr.status < 400
        @emit 'FileUploadSuccess', JSON.parse xhr.responseText
      else
        @emit 'FileUploadError', xhr

    body += @serializedToMultipart [name: "#{@id}-size", value: @file.size]
    @fileToMultipart (fileData) ->
      body += fileData
      if xhr.sendAsBinary?  # Firefox 4 - 5
        xhr.sendAsBinary body
      else if Uint8Array?  # File API, Chrome / Firefox 6.
        len = i = body.length

        arrb = new ArrayBuffer len
        ui8a = new Uint8Array arrb
        
        ui8a[i] = body.charCodeAt(i) & 0xff  while i--

        blob = new Blob [ui8a]
        xhr.send blob
    return this