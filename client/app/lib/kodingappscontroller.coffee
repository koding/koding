kd               = require 'kd'
KDController     = kd.Controller
KDCustomHTMLView = kd.CustomHTMLView

globals          = require 'globals'
Promise          = require 'bluebird'
async            = require 'async'

FSHelper         = require './util/fs/fshelper'
registerAppClass = require './util/registerAppClass'

AppClasses =
  ace: require 'ace'
  finder: require 'finder'
  home: require 'home'
  analytics: require 'analytics'
  ide: require 'ide'
  'stack-editor': do ->
    if Cookies.get 'use-ose'
    then require 'stack-editor'
    else require 'new-stack-editor'
  testrunner: require 'testrunner'


module.exports = class KodingAppsController extends KDController

  name    = 'KodingAppsController'
  version = '0.1'

  registerAppClass this, { name, version, background: yes }

  @loadInternalApp = (name, callback) ->

    unless globals.config.apps[name]
      kd.warn message = "#{name} is not available to run!"
      return callback { message }

    if name.capitalize() in Object.keys globals.appClasses
      kd.warn "#{name} is already imported"
      return callback null

    app = globals.config.apps[name]

    @putAppScript app, (err, res) =>

      AppClass = AppClasses[res.app.identifier] or kd.Object

      register = (klass) ->
        registerAppClass klass
        callback err, res

      if dependencies = AppClass.options?.dependencies
      then @loadDependencies dependencies, -> register AppClass
      else register AppClass


  @loadDependencies = (dependencies, callback) ->
    queue = []

    for dependency in dependencies
      queue.push do (dependency) => (fin) =>
        @loadInternalApp dependency, -> fin()

    async.parallel queue, callback

  ## This is the most important method to put & run additional apps on Koding
  ## Please make sure about your changes on it.
  @putAppScript = (app, callback = kd.noop) ->

    if app.style
      cb = if app.script then kd.noop else callback
      @appendHeadElement 'style',  \
        { app: app, url:app.style, identifier:app.identifier, force: yes }, cb

    if app.script
      @appendHeadElement 'script', \
        { app: app, url:app.script, identifier:app.identifier, force: yes }, callback

    return callback null, { app }

  @unloadAppScript = (app, callback = kd.noop) ->

    identifier = app.identifier.replace /\./g, '_'

    @destroyScriptElement 'style', identifier
    @destroyScriptElement 'script', identifier

    kd.utils.defer -> callback()


  @appendHeadElement = Promise.promisify (type, { app, identifier, url, force }, callback = (->)) ->

    identifier  = identifier.replace /\./g, '_'
    domId       = "internal-#{type}-#{identifier}"
    vmName      = getVMNameFromPath url
    tagName     = type

    # Which means this is an invm-app
    if vmName

      file = FSHelper.createFileInstance { path: url }
      file.fetchContents (err, partial) =>
        return  if err

        obj = new KDCustomHTMLView { domId, tagName }
        obj.getElement().textContent = partial

        @destroyScriptElement type, identifier  if force

        if type is 'script'
          obj.once 'viewAppended', -> callback null
        else
          callback null

        kd.utils.defer -> obj.appendToSelector 'head'

    else
      bind = ''
      load = kd.noop

      if type is 'style'
        tagName    = 'link'
        attributes =
          rel      : 'stylesheet'
          href     : url
        bind       = 'load'
        load       = -> callback null, { app, type, url }
      else
        attributes =
          type     : 'text/javascript'
          src      : url
        bind       = 'load'
        load       = -> callback null, { app, type, url }

      @destroyScriptElement type, identifier  if force

      global.document.head.appendChild (new KDCustomHTMLView {
        domId, tagName, attributes, bind, load
      }).getElement()

  @destroyScriptElement = (type, identifier) ->
    (global.document.getElementById "internal-#{type}-#{identifier}")?.remove()

  @appendHeadElements = (options, callback) ->
    { items, identifier } = options

    Promise.reduce(items, (acc, { url, type }, index) ->
      KodingAppsController.appendHeadElement type, {
        identifier : "#{identifier}-#{index}"
        url
      }

    , 0)
    # .timeout(5000)
    # .catch(warn)
    .nodeify callback

  getVMNameFromPath = (path) -> (/^\[([^\]]+)\]/g.exec path)?[1]
