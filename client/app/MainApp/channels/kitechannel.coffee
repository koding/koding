class KiteChannel

  constructor:(kiteName)->
    return KD.remote.mq.subscribe @getName kiteName

  getName:(kiteName)->
    username = KD.whoami()?.profile?.nickname ? 'unknown'
    "#{Bongo.createId 128}.#{username}.kite-#{kiteName}"

window.KiteChannel = KiteChannel