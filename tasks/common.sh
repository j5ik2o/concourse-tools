SBT_OPTS="-Xms4g -Xmx4g -XX:MaxMetaspaceSize=8g-Xss10M -XX:+CMSClassUnloadingEnabled"

git_config() {
  set +x
  mkdir -p $HOME/.ssh
  echo "${GITHUB_PRIVATE_KEY}" > ${HOME}/.ssh/id_rsa.github
  chmod 400 ${HOME}/.ssh/id_rsa.github
  echo -e "Host *\n  TCPKeepAlive yes\n\tIdentitiesOnly yes\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null\n  IdentityFile ${HOME}/.ssh/id_rsa.github\n" > ${HOME}/.ssh/config
  echo -e "[user]\n\tname = ${GIT_NAME}\n\temail = ${GIT_EMAIL}\n" > ${HOME}/.gitconfig
  unset GITHUB_PRIVATE_KEY
  set -x
}

git_log() {
  RESULT=$(git --no-pager log --date=iso --pretty=format:"commit : %H%ndate : %ad%nauthor : %an <%ae>%nsubject : %s%n" -n 1)
  echo -e "$RESULT"
}
