module.exports = (options = {}, callback) ->
  {type, endPoint, data, async} = options
  type = 'POST'  unless type

  async or= yes

  return callback {message: "endPoint not set"}  unless endPoint

  xhr = new XMLHttpRequest()
  xhr.open type, endPoint, async
  xhr.setRequestHeader "Content-Type", "application/json;"
  xhr.onload = (result) =>
    try
      response = JSON.parse xhr.responseText
    catch e
      return callback { message : "invalid json: could not parse response", code: xhr.status }

    # 0     - connection failed
    # >=400 - http errors
    if xhr.status is 0 or xhr.status >= 400
      return callback { message: response.description}

    return if xhr.readyState isnt 4

    if xhr.status not in [200, 304]
      return callback { message: response.description}

    return callback null, response

  requestData = JSON.stringify data  if data

  return xhr.send requestData
