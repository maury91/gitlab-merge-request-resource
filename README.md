# GitLab Merge Request Concourse Resource

A concourse resource to check for new merge requests on GitLab and update the merge request status.

## Source Configuration

```yaml
resource_types:
- name: merge-request
  type: docker-image
  source:
    repository: mastertinner/gitlab-merge-request-resource

resources:
- name: repo-mr
  type: merge-request
  source:
    uri: https://gitlab.com/myname/myproject.git
    private_token: XXX
    username: my_username
    password: xxx
```

* `uri`: The location of the repository (required)
* `private_token`: Your GitLab user's private token (required, can be found in your profile settings)
* `private_key`: The private SSH key for SSH auth when pulling

  Example:

  ```yaml
  private_key: |
    -----BEGIN RSA PRIVATE KEY-----
    MIIEowIBAAKCAQEAtCS10/f7W7lkQaSgD/mVeaSOvSF9ql4hf/zfMwfVGgHWjj+W
    <Lots more text>
    DWiJL+OFeg9kawcUL6hQ8JeXPhlImG6RTUffma9+iGQyyBMCGd1l
    -----END RSA PRIVATE KEY-----
  ```

* `username`: The username for HTTP(S) auth when pulling
* `password`: The password for HTTP(S) auth when pulling
* `no_ssl`: Set to `true` if the GitLab API should be used over HTTP instead of HTTPS
* `skip_ssl_verification`: Optional. Connect to GitLab insecurely - i.e. skip SSL validation. Defaults to false if not provided.

> Please note that you have to provide either `private_key` or `username` and `password`.

## Behavior

### `check`: Check for new merge requests

Checks if there are new merge requests or merge requests with new commits.

### `in`: Clone merge request source branch

`git clone`s the source branch of the respective merge request.

### `out`: Update a merge request's merge status

Updates the merge request's `merge_status` which displays nicely in the GitLab UI and allows to only merge changes if they pass the test.

#### Parameters

* `repository`: The path of the repository of the merge request's source branch (required)
* `status`: The new status of the merge request (required, can be either `pending`, `running`, `success`, `failed`, or `canceled`)
* `build_label`: The label of the build in GitLab (optional, defaults to `"Concourse"`)
* `comment`: Add a comment to the MRs open on the branch that is being target by concourse. Could be an object with `text/file` fields.
If just the `file` or `text` is specified it is used to populate the field, if both file and text are specified then the file is substituted in to replace `$FILE_CONTENT` in the text.

## Example

```yaml
jobs:
- name: test-merge-request
  plan:
  - get: repo
    resource: repo-mr
    trigger: true
  - put: repo-mr
    params:
      repository: repo
      status: running
  - task: run-tests
    file: repo/ci/tasks/run-tests.yml
  on_failure:
    put: repo-mr
    params:
      repository: repo
      status: failed
  on_success:
    put: repo-mr
    params:
      repository: repo
      status: success
      comment:
        file: out/commt.txt
        text: |
          Add new comment.
          $FILE_CONTENT
```
