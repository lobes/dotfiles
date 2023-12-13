source ~/.variables
source ~/.functions
source ~/.aliases

# Make sure this appears after rvm, git-prompt and other shell extensions that manipulate the prompt.
eval "$(direnv hook bash)"
