kd = require 'kd'
globals = require 'globals'
unregisterAppClass = require './unregisterAppClass'
registerRoute = require './registerRoute'
registerRoutes = require './registerRoutes'

module.exports = (fn, options) ->

  options = fn.options or options or {}

  return kd.error 'AppClass is missing a name!'  unless options.name

  if globals.appClasses[options.name]

    if globals.config.apps[options.name]
      return kd.warn "AppClass #{options.name} cannot be used, since its conflicting with an internal Koding App."
    else
      kd.warn "AppClass #{options.name} is already registered or the name is already taken!"
      kd.warn 'Removing the old one. It was ', globals.appClasses[options.name]
      unregisterAppClass options.name

  options.multiple      ?= no           # a Boolean
  options.background    ?= no           # a Boolean
  options.hiddenHandle  ?= no           # a Boolean
  options.openWith     or= 'lastActive' # a String "lastActive","forceNew" or "prompt"
  options.behavior     or= ''           # a String "application", or ""
  options.thirdParty    ?= no           # a Boolean
  options.menu         or= null         # <Array<Object{title: string, eventName: string, shortcut: string}>>
  options.labels       or= []           # <Array<string>> list of labels to use as app name
  options.version       ?= '1.0'        # <string> version
  options.route        or= null         # <string> or <Object{slug: string, handler: function}>
  options.routes       or= null         # <string> or <Object{slug: string, handler: function}>
  options.styles       or= []           # <Array<string>> list of stylesheets

  { routes, route, name, background }  = options

  if route
  then registerRoute name, route
  else if routes
  then registerRoutes name, routes

  Object.defineProperty globals.appClasses, name,
    configurable  : yes
    enumerable    : yes
    writable      : no
    value         : { fn, options }
