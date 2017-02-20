#!/usr/bin/env bats
# inspired by https://github.com/pimterry/git-confirm/blob/master/test/test-hook.bats

load 'libs/bats-support/load'
load 'libs/bats-assert/load'

BASE_DIR=$(dirname $BATS_TEST_DIRNAME)
# Set up a directory for our git repo
TMP_DIRECTORY=$(mktemp -d)
ORIGIN_DIRECTORY=$(mktemp -d)

setup() {
  # in order to run this test on CircleCI we need to reset this
  unset CIRCLECI;

  # Set up a git repo
  cd $TMP_DIRECTORY
  git init

  export USER_EMAIL="test@update-yarn-lock-file";
  export USER_NAME="Git Tests";

  git config user.email $USER_EMAIL
  git config user.name $USER_NAME

  # Set up a git repo
  cd $ORIGIN_DIRECTORY
  git init --bare

  git config core.sharedrepository 1
  git config receive.denyCurrentBranch ignore

  cd $TMP_DIRECTORY
  git remote add origin $ORIGIN_DIRECTORY
}

teardown() {
  if [ $BATS_TEST_COMPLETED ]; then
    echo "Deleting $TMP_DIRECTORY"
    rm -rf $TMP_DIRECTORY
    rm -rf $ORIGIN_DIRECTORY
  else
    echo "** Did not delete $TMP_DIRECTORY, as test failed **"
  fi

  cd $BATS_TEST_DIRNAME
}

circle_env() {
  echo "TEST: circle_env()";
  export CIRCLECI=1;
  echo "/TEST: circle_env()";
}

greenkeeper_branch() {
  echo "TEST: greenkeeper_branch()";
  export CIRCLE_BRANCH="greenkeeper/no-op";
  echo "/TEST: greenkeeper_branch()";
}

# create 2 commits so we have some history
# 2nd commit contains a good "update" from greenkeeper (with a lockfile)
commit_git_update() {
  echo "TEST: commit_git_update()";
  yarn init -y          # package.json
  yarn add no-op@1.0.1  # package is required for a yarn.lock file to be created
  echo "node_modules" > .gitignore
  git add .gitignore package.json yarn.lock
  git commit -m "initial commit"

  yarn add no-op@1.0.2
  git add package.json yarn.lock
  git commit -m "fix(package): update no-op to version 1.0.2"
  echo "/TEST: commit_git_update()";
}

# commit contains an "update" from greenkeeper (without a lockfile)
commit_git_update_without_lock() {
  echo "TEST: commit_git_update_without_lock()";
  yarn add no-op@1.0.3 --no-lockfile
  git checkout -b $CIRCLE_BRANCH
  git add package.json
  git commit -m "fix(package): update no-op to version 1.0.3"
  echo "/TEST: commit_git_update_without_lock()";
}

@test "exit when run outside CircleCI environment" {
  run "$BASE_DIR/bin/update-yarn-lock-file"
  assert_failure
  assert_line ">> must be run in CircleCI"
}

@test "exit if not in a greenkeeper branch" {
  circle_env
  run "$BASE_DIR/bin/update-yarn-lock-file"
  assert_success
  assert_line ">> not a greenkeeper branch"
}

@test "exit if git commit does not contain word 'update'" {
  circle_env
  greenkeeper_branch
  run "$BASE_DIR/bin/update-yarn-lock-file"
  assert_success
  assert_line ">> not an update commit"
}

@test "exit when yarn check passes" {
  circle_env
  greenkeeper_branch
  commit_git_update
  run "$BASE_DIR/bin/update-yarn-lock-file"
  assert_success
  assert_line ">> yarn check passed, yarn.lock does not need to update"
}

@test "adds new yarn.lock to git and finishes" {
  circle_env
  greenkeeper_branch
  commit_git_update
  commit_git_update_without_lock
  run "$BASE_DIR/bin/update-yarn-lock-file"
  assert_success
  run git log -1 --pretty=%B
  assert_line "chore(yarn): update yarn.lock"
}
