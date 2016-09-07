#!/bin/bash
#source build-esen.sh

# check if slack webhook url is present
if [ -z "$WERCKER_TEMPLATE_VERSION_NOTIFIER_SLACK_URL" ]; then
  fail "Please provide a Slack webhook URL"
fi

if [ -z "$WERCKER_TEMPLATE_VERSION_NOTIFIER_TEMPLATE_URL" ]; then
  fail "Please provide a github URL for the template"
fi

# check if a '#' was supplied in the channel name
if [ "${WERCKER_TEMPLATE_VERSION_NOTIFIER_SLACK_CHANNEL:0:1}" = '#' ]; then
  export WERCKER_TEMPLATE_VERSION_NOTIFIER_SLACK_CHANNEL=${WERCKER_TEMPLATE_VERSION_NOTIFIER_SLACK_CHANNEL:1}
fi

if [ -z "$WERCKER_TEMPLATE_VERSION_NOTIFIER_TEMPLATE_AUTH" ]; then
    template=$(curl --header "Accept: application/vnd.github.v3.raw" --location "$WERCKER_TEMPLATE_VERSION_NOTIFIER_TEMPLATE_URL")
else
    template=$(curl --header "Authorization: token $WERCKER_TEMPLATE_VERSION_NOTIFIER_TEMPLATE_AUTH" --header "Accept: application/vnd.github.v3.raw" --location "$WERCKER_TEMPLATE_VERSION_NOTIFIER_TEMPLATE_URL")
fi

if [ "$(echo "$template" | grep -c "template_version:" )" != "1" ]; then
    fail "There was more than 1 instance of template_version in the template file."
else
    newest_version=$(echo "$template" | grep "template_version:" | awk -F ':' '{print $2}' | tr -d " \r\n\t")
fi

current_version=$WERCKER_TEMPLATE_VERSION_NOTIFIER_TEMPLATE_VERSION

#Check version match
if [ "$current_version" = "$newest_version" ]; then
    # Up to date
    info "Current version and template version match"
    return 0
fi

info "sending message"
export WERCKER_GIT_COMMIT_SHORT=$(echo "$WERCKER_GIT_COMMIT" | cut -c1-7)
export MESSAGE="Wercker template version mismatch for $WERCKER_APPLICATION_NAME by $WERCKER_STARTED_BY on branch $WERCKER_GIT_BRANCH (<https://$WERCKER_GIT_DOMAIN/$WERCKER_GIT_OWNER/$WERCKER_GIT_REPOSITORY/commit/$WERCKER_GIT_COMMIT|$WERCKER_GIT_COMMIT_SHORT>). Current version is $current_version and newest version is $newest_version."
export FALLBACK="Wercker template version mismatch for $WERCKER_APPLICATION_NAME by $WERCKER_STARTED_BY on branch $WERCKER_GIT_BRANCH. Current version is $current_version and newest version is $newest_version."
export COLOR="danger"

# construct the json
json="{"

# channels are optional, dont send one if it wasnt specified
if [ -n "$WERCKER_TEMPLATE_VERSION_NOTIFIER_SLACK_CHANNEL" ]; then 
    json=$json"\"channel\": \"#$WERCKER_TEMPLATE_VERSION_NOTIFIER_SLACK_CHANNEL\","
fi

if [ -z "$WERCKER_TEMPLATE_VERSION_NOTIFIER_ICON_EMOJI" ]; then
  export ICON_VALUE=":wercker:"
else
  export ICON_VALUE=$WERCKER_TEMPLATE_VERSION_NOTIFIER_ICON_EMOJI
fi

json=$json"
    \"username\": \"wercker\",
    \"icon_emoji\":\"$ICON_VALUE\",
    \"attachments\":[
      {
        \"fallback\": \"$FALLBACK\",
        \"text\": \"$MESSAGE\",
        \"color\": \"$COLOR\"
      }
    ]
}"

# post the result to the slack webhook
RESULT=$(curl -d "payload=$json" -s "$WERCKER_TEMPLATE_VERSION_NOTIFIER_SLACK_URL" --output "$WERCKER_STEP_TEMP"/result.txt -w "%{http_code}")
cat "$WERCKER_STEP_TEMP/result.txt"

if [ "$RESULT" = "500" ]; then
  if grep -Fqx "No token" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "No token is specified."
  fi

  if grep -Fqx "No hooks" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "No hook can be found for specified subdomain/token"
  fi

  if grep -Fqx "Invalid channel specified" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "Could not find specified channel for subdomain/token."
  fi

  if grep -Fqx "No text specified" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "No text specified."
  fi
fi

if [ "$RESULT" = "404" ]; then
  fail "Subdomain or token not found."
fi
