# This file designates test suites to test run sets to be executed in
# parallel.
#
# Data structure is an array of arrays.  An inner array defines a
# parallel set.
#
# Order of inner array is irrelevant because each set will be started
# at the very same time if a host test server is reserved per set.
#
# Keep total duration of parallel sets close to each other.  This is
# the only thing to consider while adding a test suite to a set or
# moving a test suite from one set to another.
#
# Total test run will take long as the longest set.  If a set is
# taking longer than set goal then a new set can be added to list.
#
# Amount of test suites added to a set is not an issue as long as
# duration of that set is not taking so long than others.
#
# Test suites in a set will be executed consecutively.

module.exports = [

  [
    { name: 'register' }
    { name: 'login' }
    { name: 'logout' }
    { name: 'activity likeunlike' }
  ]

  [
    { name: 'pricing payment' }
    { name: 'activity post' }
    { name: 'staticpages loggedout' }
  ]

  [
    { name: 'messages privatemessage' }
    { name: 'account accountsettings' }
    { name: 'activity postwith' }
  ]

  [
    { name : 'activity edit' }
    { name : 'activity delete' }
  ]

  [
    { name : 'unittests' }
    { name : 'activity others' }
    { name : 'account accountpage' }
  ]

  [
    { name : 'ide file' }
    { name : 'ide folder' }
  ]

  [
    { name : 'ide search' }
    { name : 'ide workspace' }
  ]

  [
    { name : 'ide terminal' }
    { name : 'pricing invalidCardDetails' }
  ]

  [
    { name : 'ide general' }
    { name : 'ide layout' }
  ]

  [
    { name : 'collaboration collaboration' }
    { name : 'environments snapshot' }
  ]

  # [
  #   { name : 'collaboration start', NIGHTWATCH_OPTIONS: '--env host,participant' }
  # ]

  [
    { name : 'environments vm' }
  ]

  [
    { name : 'environments paidaccount' }
  ]

  [
    { name : 'environments domain' }
    { name : 'teams teams' }
  ]

]
