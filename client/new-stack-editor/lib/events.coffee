jspath = require 'jspath'

module.exports = do ->

  events = [
    'CredentialChangesRevertRequested'
    'CredentialChangesSaveRequested'
    'CredentialSelectionChanged'
    'CredentialFilterChanged'
    'SelectedProviderChanged'
    'CredentialListUpdated'
    'StackWizardCancelled'
    'InitializeRequested'
    'TemplateDataChanged'
    'ProviderSelected'
    'LazyLoadFinished'
    'LazyLoadStarted'
    'ToolbarAction'
    'ToggleSideView'
    'ShowSideView'
    'WarnUser'
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
