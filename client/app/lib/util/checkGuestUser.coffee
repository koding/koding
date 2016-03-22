# Guest user is a registered user but treated as an unregistered
# user ~ SZ

# This is last guard that we can take for guestuser issue ~ GG

module.exports = (account) -> account.profile?.nickname is 'guestuser'
