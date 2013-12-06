forceTwoDigits = (val) ->
  if val < 10
    return "0#{val}"
  return val

formatDate = (date) ->
  year = date.getFullYear()
  month = date.getMonth()
  day = forceTwoDigits date.getDate()
  hour = forceTwoDigits date.getHours()
  minute = forceTwoDigits date.getMinutes()

  # What about i18n? Does GoogleBot crawl in different languages?
  months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  monthName = months[month]
  return "#{monthName} #{day}, #{year} #{hour}:#{minute}"

getFullName = (account) ->
  fullName = "A koding user"
  if account?.data?.profile?.firstName?
    fullName = account.data.profile.firstName + " "

  if account?.data?.profile?.lastName?
    fullName += account.data.profile.lastName
  return fullName

getNickname = (account) ->
  nickname = "/"
  if account?.data?.profile?.nickname?
    nickname = account.data.profile.nickname
  return nickname

getUserHash = (account) ->
  hash = ""
  if account?.data?.profile?.hash?
    hash = account.data.profile.hash
  return hash

module.exports = {
  forceTwoDigits
  formatDate
  getFullName
  getNickname
  getUserHash
}