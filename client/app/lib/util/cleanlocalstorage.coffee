globals   = require 'globals'
blacklist = require './blacklistforlocalstorage'


module.exports = class CleanLocalStorage
  storage = global.localStorage

  console.log "storage ", storage
  for k, v of global.localStorage
    if k in blacklist
      storage.removeItem k
