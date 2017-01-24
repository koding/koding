cdns =
  'koding-client': 'https://koding-client.s3.amazonaws.com/'
  'koding-assets': 'https://koding-assets.s3.amazonaws.com/'
  'kodingdev-client': 'https://kodingdev-client.s3.amazonaws.com/'
  'kodingdev-assets': 'https://kodingdev-assets.s3.amazonaws.com/'

cdnPath = '/cdn'

module.exports = (url) ->
  return url unless url

  for key, location of cdns
    if url.startsWith location
      return "#{cdnPath}/#{key}/#{url.substring(location.length, url.length)}"
