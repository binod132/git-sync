#!/bin/bash

# Set the URL for your git repository and the script to be executed on changes
REPO_URL="https://github.com/binod132/git-sync.git"
REPO_DIR="git-sync"
SCRIPT_TO_RUN="../script.sh"
BRANCH="main"  # or whichever branch you're working with
MONITOR_FILE="test.txt"  # The file you want to monitor for changes

# Check if the repository exists locally
if [ ! -d "$REPO_DIR" ]; then
  echo "Repository not found locally, cloning..."
  git clone "$REPO_URL" "$REPO_DIR" || { echo "Failed to clone repository"; exit 1; }
fi

# Navigate to the git repository
cd "$REPO_DIR" || { echo "Failed to navigate to repo directory"; exit 1; }

# Check if it's a valid git repository
if ! git status &>/dev/null; then
  echo "Not a git repository, exiting."
  exit 1
fi

echo "Monitoring repository at $REPO_DIR for changes in $MONITOR_FILE..."

# Start monitoring the repository for changes
while true; do
  # Fetch the latest commit hash from the remote repository without checking out files
  REMOTE_COMMIT_HASH=$(git ls-remote origin "$BRANCH" | awk '{print $1}')

  # Get the last commit that modified the monitored file
  FILE_COMMIT_HASH=$(git log -n 1 --pretty=format:"%H" -- "$MONITOR_FILE")

  # Get the current commit hash in the local repository
  LOCAL_COMMIT_HASH=$(git rev-parse HEAD)

  # Check if the local commit hash matches the remote commit hash
  if [ "$LOCAL_COMMIT_HASH" != "$REMOTE_COMMIT_HASH" ]; then
    echo "Changes detected in repository, checking if $MONITOR_FILE was updated..."

    # Pull the latest changes from the remote repository
    git pull origin "$BRANCH" || { echo "Failed to pull latest changes"; continue; }

    # After pulling, check if the monitored file is part of the latest commit
    UPDATED_COMMIT_HASH=$(git log -n 1 --pretty=format:"%H" -- "$MONITOR_FILE")
    
    # If the commit hash for the file is different from the last known commit hash
    if [ "$UPDATED_COMMIT_HASH" != "$FILE_COMMIT_HASH" ]; then
      echo "Changes detected in $MONITOR_FILE, executing the script..."
      # Execute the desired script after the git pull
      bash "$SCRIPT_TO_RUN"
      FILE_COMMIT_HASH=$UPDATED_COMMIT_HASH
    else
      echo "No changes detected in $MONITOR_FILE, skipping execution."
    fi
  else
    echo "No changes detected in the repository, waiting for new commits..."
  fi

  # Sleep for a while before checking again (e.g., every 30 seconds)
  sleep 30
done

