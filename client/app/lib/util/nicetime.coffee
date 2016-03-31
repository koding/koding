module.exports = do ->

  niceify = (duration) ->

    past = no

    if duration < 0
      past     = yes
      duration = Math.abs duration

    duration = new Number(duration).toFixed 2
    durstr   = ''
    second   = 1
    minute   = second * 60
    hour     = minute * 60
    day      = hour * 24

    durstr = if duration < minute then 'less than a minute'
    else if duration < minute * 2 then 'about a minute'
    else if duration < hour       then Math.floor(duration / minute) + ' minutes'
    else if duration < hour * 2   then 'about an hour'
    else if duration < day        then 'about ' + Math.floor(duration / hour) + ' hours'
    else if duration < day * 2    then '1 day'
    else if duration < day * 365  then Math.floor(duration / day) + ' days'
    else 'over a year'

    durstr += ' ago'  if past

    return durstr

  (duration, to) ->

    if not to
      niceify duration
    else if duration and to
      from = duration
      to   = to
      niceify to - from
    else if not duration and to
      from = new Date().getTime() / 1000
      to   = to
      niceify to - from
