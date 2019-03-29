#!/bin/sh

# Display commands being run.
set -x

# If the current git message contains the phrase DISABLE_COVERAGE_CHECK, we can
# end early.
git log -1 | grep DISABLE_COVERAGE_CHECK
if [ $? -eq 0 ]; then
  exit 0 # Exit early without error as we don't want to run coverage
fi

# Make sure we get the most recent commit hash
curr_hash="$(git rev-parse HEAD)"
# We already ran the test on the current version
# File is stored in coverage/coverage-summary.json
cvg_pct="console.log(require('./coverage/coverage-summary.json').total.functions.pct)"
cvg_pct_threshold="console.log(require('./coverage/coverage-summary.json').total.functions.pct + 3)"
curr_coverage=$(node -e "$cvg_pct")
curr_coverage_threshold=$(node -e "$cvg_pct_threshold")
# Go back a step in the git chain
git checkout HEAD~1
# We are in HEAD-1
# Run coverage check and get it output as ./coverage/coverage-summary.json
yarn test > /dev/null
# File is stored in coverage/coverage-summary.json
prev_coverage=$(node -e $cvg_pct)

# Now return to the commit
git checkout "$curr_hash"
# Run coverage check and get it output as ./coverage/coverage-summary.json

if [ $prev_coverage -lt $curr_coverage_threshold ]; then
  # This change reduces function code coverage.
  # This is not good.
  echo "This change reduces code coverage from ${prev_coverage}% to ${curr_coverage}%"
  exit 1
else
  echo "Coverage has changed from ${prev_coverage}% to ${curr_coverage}%"
fi
