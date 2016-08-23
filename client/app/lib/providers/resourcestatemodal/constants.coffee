module.exports =
  INITIAL_PROGRESS_VALUE                : 10
  COMPLETE_PROGRESS_VALUE               : 100
  CREDENTIAL_BOOTSTRAP_TIMEOUT          : 30000
  CREDENTIAL_VERIFICATION_TIMEOUT       : 10000
  CREDENTIAL_VERIFICATION_ERROR_MESSAGE : '''
    We couldn't verify this credential, please check the ones you
    used or add a new credential to be able to continue to the
    next step.
  '''
  BUILD_LOG_FILE_PATH                   : '/var/log/cloud-init-output.log'
  BUILD_LOG_TAIL_OFFSET                 : 15
  MAX_BUILD_PROGRESS_VALUE              : 60
  DEFAULT_BUILD_DURATION                : 300
  TIMEOUT_DURATION                      : 120
  MACHINE_PING_TIMEOUT                  : 5
