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
    { name: 'teams teams' }
    { name: 'dashboard myaccount' }
    { name: 'dashboard stacks' }
    { name: 'dashboard virtualmachines' }
    { name: 'dashboard myteam' }
    { name: 'dashboard credentials' }
    { name: 'dashboard utilities' }
    { name: 'dashboard onboarding' }
    { name: 'dashboard sidebar' }
  #   { name: 'dashboard teambilling' }
  ]

  [
    { name: 'teams teams' }
    # { name: 'unittests' }
  ]

  [
    { name: 'ide file' }
    { name: 'ide folder' }
  ]

  [
    { name: 'ide layout' }
  ]

  [
    { name: 'ide search' }
    { name: 'ide general' }
  ]

  [
    { name: 'ide terminal' }
    { name: 'ide settings' }
  ]

  # [
  #   { name: 'collaboration collaborationsingle' }
  #   { name: 'collaboration collaborationpermission', NIGHTWATCH_OPTIONS: '--env host,participant' }
  # ]

  # [
  #   { name: 'collaboration start', NIGHTWATCH_OPTIONS: '--env host,participant' }
  # ]

  # [
  #   { name: 'collaboration collaborationsession', NIGHTWATCH_OPTIONS: '--env host,participant' }
  # ]

  # [
  #   { name: 'collaboration collaborationfile', NIGHTWATCH_OPTIONS: '--env host,participant' }
  # ]

  # [
  #   { name: 'vmsharing vmsharing', NIGHTWATCH_OPTIONS: '--env host,participant' }
  # ]

  # [
  #   { name: 'environments vm' }
  # ]

  # [
  #   { name: 'environments domain' }
  # ]

]
