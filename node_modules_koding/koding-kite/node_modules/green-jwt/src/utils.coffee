
exports.base64urlEncode = base64urlEncode = (str) ->
  base64urlEscape(new Buffer(str).toString('base64'))

exports.base64urlDecode = base64urlDecode = (str) ->
  new Buffer(base64urlUnescape(str), 'base64').toString()

exports.base64urlEscape = base64urlEscape = (str) ->
  str.replace(/\+/g, '-').replace(/\//g, '_').replace(/\=/g, '')

exports.base64urlUnescape = base64urlUnescape = (str) ->
  str += Array(5 - str.length % 4).join('=')
  str.replace(/\-/g, '+').replace(/_/g, '/')


