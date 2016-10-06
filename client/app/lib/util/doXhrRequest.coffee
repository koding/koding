module.exports = doXhrRequest = (options = {}, callback) ->

  { type, endPoint, data, async, timeout } = options
  type = 'POST'  unless type

  async or= yes

  return callback { message: 'endPoint not set' }  unless endPoint

  xhr = new XMLHttpRequest()
  xhr.open type, endPoint, async
  xhr.setRequestHeader 'Content-Type', 'application/json;'
  xhr.onload = (result) ->
    return if xhr.readyState isnt 4

    # 0 - connection failed
    if xhr.status is 0 or xhr.status >= 500
      return callback {
        message : 'internal server error'
        code    : xhr.status
      }

    if xhr.status is 202
      response = { status: xhr.status }
    else
      try
        response = JSON.parse xhr.responseText
      catch e
        return callback {
          message : 'invalid json: could not parse response'
          code    : xhr.status
        }


    # >=300 - http errors
    if xhr.status >= 300
      return callback {
        message : response.description
        code    : xhr.status
      }

    return callback null, response

  if timeout?
    xhr.timeout   = timeout
    xhr.ontimeout = ->
      return callback {
        message : 'operation timed out'
        code    : xhr.status
      }

  requestData = JSON.stringify data  if data

  return xhr.send requestData
