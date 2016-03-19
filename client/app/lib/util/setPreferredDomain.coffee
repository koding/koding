kookies = require 'kookies'
# This function checks current user's preferred domain and
# set's it to preferredDomainCookie

module.exports = (account) ->
  preferredDomainCookieName = 'kdproxy-preferred-domain'

  { preferredKDProxyDomain } = account
  if preferredKDProxyDomain and preferredKDProxyDomain isnt ''
    # if cookie name is already same do nothing
    return  if (kookies.get preferredDomainCookieName) is preferredKDProxyDomain

    # set cookie name
    kookies.set preferredDomainCookieName, preferredKDProxyDomain

    # there can be conflicts between first(which is defined below) route
    # and the currect builds router, so reload to main page from server
    global.location.reload(true)
