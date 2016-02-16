fs           = require 'fs'
path         = require 'path'
electron     = require 'electron'
{ app }      = electron

SUPPORT_PATH = path.join app.getPath('appData'), app.getName()
STORAGE_FILE = 'appstorage.json'
STORAGE_PATH = path.join SUPPORT_PATH, STORAGE_FILE

module.exports = class Storage

  constructor: (options = {}) ->

    @path     = options.path     or STORAGE_PATH
    @template = options.template or {}

    @init()

    @write @template  if options.reset


  init: ->

    fs.stat @path, (err) => @write @template  if err


  write: (data, callback) ->

    fs.writeFile @path, JSON.stringify(data), =>
      console.log "Storage file is saved at: #{@path}"
      callback?()


  get: ->

    try
      storage = JSON.parse fs.readFileSync @path
    catch e
      console.log e

    return storage or {}
