class KiteChannel

  constructor:(kiteName)->
    return KD.remote.mq.subscribe @getName kiteName

  getName:(kiteName)->
    nickname = KD.whoami()?.profile?.nickname ? 'unknown'
    "#{Bongo.createId 128}.#{nickname}.kite-#{kiteName}"

window.KiteChannel = KiteChannel