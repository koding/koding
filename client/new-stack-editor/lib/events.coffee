jspath = require 'jspath'

module.exports = do ->

  events = [
    'CredentialChangesRevertRequested'
    'CredentialChangesSaveRequested'
    'CredentialSelectionChanged'
    'CredentialFilterChanged'
    'CredentialListUpdated'

    'TemplateTitleChangeRequested'
    'TemplateDataChanged'

    'SelectedProviderChanged'
    'StackWizardCancelled'
    'InitializeRequested'
    'ProviderSelected'
    'LoadClonedFrom'

    'Banner.ActionClicked'
    'Banner.Close'

    'Menu.MakeTeamDefault'
    'Menu.Credentials'
    'Menu.Initialize'
    'Menu.Rename'
    'Menu.Delete'
    'Menu.Clone'
    'Menu.Test'
    'Menu.Logs'

    'LazyLoadFinished'
    'LazyLoadStarted'

    'CollapseSideView'
    'ExpandSideView'
    'ToggleSideView'
    'ShowSideView'
    'HideSideView'

    'HideWarning'
    'WarnUser'

    'GotFocus'
    'Action'

    'Log'
  ]

  obj = {}
  events.forEach (event) ->
    jspath.setAt obj, event, event

  return obj
