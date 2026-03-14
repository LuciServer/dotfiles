# Powerlevel10k configuration

# Prompt layout
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  dir
  vcs
  prompt_char
)

typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status
  command_execution_time
  background_jobs
  kubecontext
  aws
  gcloud
  context
  time
)

# Use ASCII icons for maximum compatibility
typeset -g POWERLEVEL9K_MODE=ascii

# Prompt style
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false
typeset -g POWERLEVEL9K_ICON_PADDING=none

# Directory
typeset -g POWERLEVEL9K_DIR_FOREGROUND=31
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=39
typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true

typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80

# Git
typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)
typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1
typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR=76

# Prompt symbol
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_CONTENT_EXPANSION='>'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_CONTENT_EXPANSION='>'
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND=76
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND=196

# Exit status
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_STATUS_ERROR=false

# Command timing
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX='took '

# Kubernetes
typeset -g POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND='kubectl|helm|k9s|kubectx|kubens'

# AWS
typeset -g POWERLEVEL9K_AWS_SHOW_ON_COMMAND='aws|terraform|pulumi|terragrunt'

# GCloud
typeset -g POWERLEVEL9K_GCLOUD_SHOW_ON_COMMAND='gcloud|gsutil'

# SSH context
typeset -g POWERLEVEL9K_CONTEXT_PREFIX='with '
typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=180

# Time
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%I:%M:%S %p}'
typeset -g POWERLEVEL9K_TIME_PREFIX='at '

# Transient prompt
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off

# Instant prompt
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
