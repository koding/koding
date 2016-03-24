module.exports = (query) ->
  return no  unless query
  query = query.replace /^\//, ''
  (query.split '/').length is 7
