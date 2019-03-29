#!/bin/sh

# Display commands being run.
set -x

# If the current git message contains the phrase DISABLE_COVERAGE_CHECK, we can
# end early.
git log -1 | grep DISABLE_COVERAGE_CHECK
if [ $? -eq 0 ]; then
  exit 0 # Exit early without error as we don't want to run coverage
fi

# Run coverage on most recent HEAD
# Make sure we get the most recent commit hash
curr_hash="$(git rev-parse HEAD)"
git checkout HEAD~1
# We are in HEAD-1
# Run coverage check and get it output as ./coverage/coverage-summary.json
yarn test > /dev/null
# File is stored in coverage/coverage-summary.json
coverage_pct="console.log(require('./coverage/coverage-summary.json').total.functions.pct)"
prev_coverage=$(node -e $coverage_pct)

# Now go to this commit
git checkout "$curr_hash"
# Run coverage check and get it output as ./coverage/coverage-summary.json
yarn test > /dev/null
# File is stored in coverage/coverage-summary.json
coverage_pct_threshold="console.log(require('./coverage/coverage-summary.json').total.functions.pct + 3)"
curr_coverage=$(node -e "$coverage_pct_threshold")

if [ $prev_coverage -lt $curr_coverage ]; then
  # This change reduces function code coverage.
  # This is not good.
  echo "This change reduces code coverage from ${prev_coverage}% to ${curr_coverage}%"
  exit 1
else
  echo "Coverage has changed from ${prev_coverage}% to ${curr_coverage}%"
fi
