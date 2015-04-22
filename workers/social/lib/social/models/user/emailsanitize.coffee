module.exports = emailSanitize = (email)->

  email = email.toLowerCase()

  # Special rules for Gmail and Googlemail. Googlemail is for users
  # in Germany, Poland and Russia.
  if /^(.)+@(gmail|googlemail).com/.test email
    [name, domain] = email.split '@'

    # . have no meaning, they're being abused to create fake accounts
    name = name.replace '.', ''

    # + have meaning, but they ultimately belong to email before +
    # so we check for uniqueness before +, but let user save + in email
    if email.indexOf('+') > -1
      name = (name.split '+')[0]

    email = "#{name}@#{domain}"

  return email
