module.exports =
  botchedUrlRegExp     : /(([a-zA-Z]+\:)?\/\/)+(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g
  webProtocolRegExp    : /^((http(s)?\:)?\/\/)/
  domainWithTLDPattern : /^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}$/i
  subdomainPattern     : /^(?:[a-z0-9](?:[_\-](?![_\-])|[a-z0-9]){0,60}[a-z0-9]|[a-z0-9])$/i
  hasProtocol          : /^\w+\:\/\//
