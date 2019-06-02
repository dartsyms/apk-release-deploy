#!/bin/bash

# RELEASE NOTE FILE
LOG_FILE=CHANGELOG.md
TMP_LOG_FILE=CHANGELOG.tmp.md

# SEEKING LABELS ON COMMIT SUBJECTS
BUGS=";B"
FEATURES=";F"
MISC=";M"
ALL="(;F|;B|;M)"

# MD TITLES
FEATURE_TAG="**Implemented enhancements:**"
BUG_TAG="**Fixed bugs:**"
MISC_TAG="**Miscellaneous:**"

TODAYS_DATE=`TZ=":US/Eastern" date -dtoday '+%F %R %z'`
TODAYS_DATE_HUMANIZED=`TZ=":US/Eastern" date -dtoday '+%B %e, %Y %R %Z'`

# LINKS
ATLASSIAN='https:\/\/myapp.atlassian.net\/browse'
ZENDESK='https:\/\/myapp.zendesk.com\/agent\/tickets'
HONEYBADGER='https:\/\/app.honeybadger.io\/projects'
FAULTS='4325\/faults'

LAST_TAG=`git describe --abbrev=0 --tags`
# LAST_TAG_DATE=`git log -1 --format=%ai "${LAST_TAG}"`
# LAST_DATE=`TZ=":US/Eastern" date -d "${LAST_TAG_DATE}" +"%F %R %z"`

print_features(){
  echo $FEATURE_TAG
  echo
  GIT_PAGER=cat git_log "$FEATURES"
  echo
}

print_bugs(){
  echo $BUG_TAG
  echo
  GIT_PAGER=cat git_log "$BUGS"
  echo
}

print_misc(){
  echo $MISC_TAG
  echo
  GIT_PAGER=cat git_log "$MISC"
  echo
}

print_date(){
  echo "## "$TODAYS_DATE_HUMANIZED
  echo
}

git_log() {
  git log "$LAST_TAG"..HEAD \
          --grep="$1" -E -i \
          --no-merges --format="- %s"
}

linkify(){
  if [[ $1 == 'MYAPP #' ]] 
  then
    J=PMGR
    LINK="[$J $2]($ATLASSIAN\/MYAPP-${2//#})"
  elif [[ $1 == 'E #' ]]
  then
    J=HONEYBADGER
    LINK="[$J $2]($HONEYBADGER\/$FAULTS\/${2//#})"
  elif [[ $1 == 'HD #' ]]
  then
    J=ZENDESK
    LINK="[$J $2]($ZENDESK\/${2//#})"
  else
    0
  fi
  
  if [[ $J ]]
  then
    REP="${1//#}${2}"
    sed -i "s/$REP/$LINK/" $LOG_FILE
  fi
}


grep_links(){
  for arg in "$@"
  do
    for line in $(sed -n "/$arg/p" $LOG_FILE)
    do
      for word in $line; do
        if [[ $word =~ ^#.* ]] 
        then
          linkify "$arg" "$word"
        fi
      done
    done
  done
}

pretty_print() {
  for arg in "$@"
  do
    # Case insesitive
    sed -i "s/$arg/ /I" $LOG_FILE
  done
}

commit(){
  git add "${LOG_FILE}"
  git commit -m "Release to production ${TODAYS_DATE_HUMANIZED}"
  git push upstream master
}

git_log_read(){
    LOG_ALL=`git_log $ALL`
    LOG_FEATURE=`git_log $FEATURES`
    LOG_BUG=`git_log $BUGS`
    LOG_MISC=`git_log $MISC`

    if [[ $LOG_ALL ]]
      then
      print_date
      
      if [[ $LOG_FEATURE ]]
      then
        print_features
      fi
      
      if [[ $LOG_BUG ]] 
      then
        print_bugs
      fi
      if [[ $LOG_MISC ]]
      then
        print_misc
      fi
      echo
    fi
}

if [[ -e $LOG_FILE ]]
then
  # IF THERE'S NOTHING NEW DON'T DO IT
  if [ -n "$(git_log_read)" ]; then
    echo -e "$(git_log_read)\n\n" > $TMP_LOG_FILE
    
    # PREPEND CONTENTS OF NEW FILE TO CHANGELOG.md
    sed -i "3r $TMP_LOG_FILE" $LOG_FILE
    grep_links 'MYAPP #' 'E #' 'HD #'
    pretty_print ';f' ';b' ';m'
    
    rm $TMP_LOG_FILE
    commit
  fi
else
  echo "# Release Notes" > $LOG_FILE
  echo ---------------------- >> $LOG_FILE
  echo >> $LOG_FILE

  git_log_read >> $LOG_FILE

  grep_links 'MYAPP #' 'E #' 'HD #'
  pretty_print ';f' ';b' ';m'
  commit
fi
