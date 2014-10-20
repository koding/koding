module.exports = (site) ->

  switch site

    when 'landing'   then tags += require './tags/landing'
    when 'hackathon' then tags += require './tags/hackathon'
    else tags += ''


  return tags
