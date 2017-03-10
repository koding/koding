whoami = require './whoami'
globals = require 'globals'
KodingKontrol = require 'app/kite/kodingkontrol'

module.exports = getKDCmd = (callback) ->

  whoami().fetchOtaToken (err, token) ->
    return callback err  if err

    cmd = if globals.config.environment in ['dev', 'default', 'sandbox']
    then "export KONTROLURL=#{KodingKontrol.getKontrolUrl()}; curl -sL https://sandbox.kodi.ng/c/d/kd | bash -s #{token}"
    else "curl -sL https://kodi.ng/c/p/kd | bash -s #{token}"

    callback null, cmd
