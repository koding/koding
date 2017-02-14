jspath = require 'jspath'

module.exports = do ->

  events = [
    'CredentialChangesRevertRequested'
    'CredentialChangesSaveRequested'
    'WarnAboutMissingCredentials'
    'CredentialSelectionChanged'
    'CredentialFilterChanged'
    'SelectedProviderChanged'
    'CredentialListUpdated'
    'StackWizardCancelled'
    'InitializeRequested'
    'TemplateDataChanged'
    'ToggleCredentials'
    'ProviderSelected'
    'LazyLoadFinished'
    'LazyLoadStarted'
    'ShowCredentials'
    'GotFocus'
    'Log'
    'MenuAction'
    'Menu.Test'
    'Menu.Initialize'
    'Menu.MakeTeamDefault'
    'Menu.Rename'
    'Menu.Clone'
    'Menu.Credentials'
    'Menu.Logs'
    'Menu.Delete'
  ]

  obj = {}
  events.forEach (event) ->
    jspath.setAt obj, event, event

  return obj
