#!/bin/bash

# WARNING: This script will create thousands of commits and may make your repo very large and slow.
# Only run if you are sure you want to do this!

set -e

FILES=(
  "ContestLiveActivityWidget/UpcomingContestsWidget.swift"
  "krypticGrind/Models/LeaderboardManager.swift"
  "krypticGrind/Models/LiveActivityAttributes.swift"
  "krypticGrind/Models/ProblemNote.swift"
  "krypticGrind/Views/LeaderboardView.swift"
  "krypticGrind/Views/ReviewLaterView.swift"
)

echo "Starting back-in-time commits for each file and minute on July 1st, 2024 (00:00 to 13:26)..."

for FILE in "${FILES[@]}"; do
  if [ ! -f "$FILE" ]; then
    echo "File $FILE does not exist, skipping."
    continue
  fi
  git add -f "$FILE"
  for HOUR in $(seq -w 0 13); do
    if [ "$HOUR" -eq 13 ]; then
      MAX_MIN=26
    else
      MAX_MIN=59
    fi
    for MIN in $(seq -w 0 $MAX_MIN); do
      COMMIT_DATE="2024-07-01T${HOUR}:${MIN}:00+05:30"
      GIT_AUTHOR_DATE="$COMMIT_DATE" GIT_COMMITTER_DATE="$COMMIT_DATE" git commit -m "Add $FILE at $HOUR:$MIN on July 1st, 2024" --allow-empty
    done
  done
done

echo "Done!" 