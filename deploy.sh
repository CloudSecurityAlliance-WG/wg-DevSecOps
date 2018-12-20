#!/bin/bash
# TODO: replace this script when https://github.com/travis-ci/dpl/issues/694 is fixed
# Taken from https://raw.githubusercontent.com/w3c/permissions/master/deploy.sh
set -e # Exit with nonzero exit code if anything fails

errx() {
  readonly __progname=$(basename ${BASH_SOURCE})
  echo -e "[${__progname}] $@" >&2
  exit 1
}

SOURCE_BRANCH="master"
TARGET_BRANCH="gh-pages"
KEY_NAME=$(pwd)/deploy_key

main() {

  # Pull requests and commits to other branches shouldn't try to deploy, just build to verify
  if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]; then
    echo "Not a Travis PR or not matching branch ($SOURCE_BRANCH); skipping deploy."
    exit 0
  fi

  [ -z "$COMMIT_AUTHOR_EMAIL" ] && \
    errx "No COMMIT_AUTHOR_EMAIL provided; it must be set."

  if [ ! -f ${KEY_NAME} ]; then
    errx "No ${KEY_NAME} file detected; is ${KEY_NAME}.enc decrypted?"
  fi

  # Save some useful information
  REPO=`git config remote.origin.url`
  SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
  SHA=`git rev-parse --verify HEAD`
  DEST_DIR=out

  # Clone the existing $TARGET_BRANCH for this repo into $DEST_DIR/
  # Create a new empty branch if gh-pages doesn't exist yet (should only happen on first deploy)
  #  git clone $REPO $DEST_DIR
  git clone $REPO $DEST_DIR || errx "Unable to clone Git."
  pushd $DEST_DIR
  git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH || errx "Unable to checkout git."
  popd

  # Clean out existing contents in $TARGET_BRANCH clone
  rm -rf $DEST_DIR/* || exit 0

  # Adding contents within published/ to $DEST_DIR.
  cp -a published/* $DEST_DIR/ || exit 0

  # Now let's go have some fun with the cloned repo
  pushd $DEST_DIR
  git config user.name "Travis CI"
  git config user.email "$COMMIT_AUTHOR_EMAIL"

  # If there are no changes to the compiled out (e.g. this is a README update) then just bail.
  if [[ -z $(git status -s) ]]; then
    echo "No changes to the output on this push; exiting."
    exit 0
  fi

  git status

  # Commit the "changes", i.e. the new version.
  # The delta will show diffs between new and old versions.
  git add .
  git commit -m "Deploy to GitHub Pages: ${SHA}"

  eval `ssh-agent -s`
  ssh-add ${KEY_NAME}

  # Now that we're all set up, we can push.
  git push $SSH_REPO $TARGET_BRANCH || errx "Unable to push to git."
}

main "$@"

exit 0
