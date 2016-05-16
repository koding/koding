KONFIG = require 'koding-config-manager'

sanitize = (email, options = {}) ->

  options.excludeDots or= no
  options.excludePlus or= no

  [local, host]     = email.split '@'
  [username, label...] = local.split '+'

  label = label.join '+'

  # . have no meaning, they're being abused to create fake accounts
  username = excludeDots username  if options.excludeDots

  # + have meaning, but they ultimately belong to user before +
  # so we check for uniqueness before +, but let user save + in email
  username = excludePlus username  if options.excludePlus

  if label and not options.excludePlus
  then local = "#{username}+#{label}"
  else local = username

  return "#{local}@#{host}"


# Special rules for Gmail and Googlemail. Googlemail is for users
# in Germany, Poland and Russia.
checkGmail = (email) -> /^(.)+@(gmail|googlemail).com/.test email


checkBaseMail = (email) -> ///^(.)+@#{KONFIG.domains.mail}///.test email


excludeDots = (username) -> username.replace /\./g, ''


excludePlus = (username) ->
  parts[0]  if (parts = username.split '+').length


module.exports = (email, options = {}) ->

  return ''  unless email

  email = email.trim().toLowerCase()

  if checkBaseMail email
  then email
  else sanitize email, options
