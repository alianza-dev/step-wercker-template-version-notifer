# template-version-notifer
This step compares the template version embedded in the running wercker.yml file, compares it with the specified template file (stored in GitHub), and notifies a slack channel if it doesn't match.

## Options
* `slack_url` A Slack webhook URL.
* `slack_channel` (optional) The Slack channel to notify.
* `template_url` The URL to retrieve the wercker template. This template must contain a template-version-notifier step. Preferably a GitHub API URL to retrieve the raw template file.
* `template_auth` (optional) If you are using a GitHub API URL that points to a file in a private GitHub repo, use this option to specify a Personal Access Token.
* `template_version` In your template file, this specifies the most recent version of the template. In your project's wercker.yml, this specifies the template version you based your wercker.yml from.
* `icon_emoji` (optional) This specifies an emoji to use for your message avatar.

## Example

```yaml
build:
  steps:
    - alianza/template-version-notifier:
      template_version: 1.0.0
      template_url: https://api.github.com/repos/your-user/your-repo/contents/template-wercker.yml
      template_auth: your_personal_access_token
      slack_url: $SLACK_URL
      slack_channel: $SLACK_CHANNEL
```
