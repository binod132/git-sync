#!/bin/bash

# Set the URL for your git repository and the script to be executed on changes
REPO_URL="https://github.com/binod132/git-sync.git"
REPO_DIR="git-sync"
SCRIPT_TO_RUN="../script.sh"
BRANCH="main"  # or whichever branch you're working with

# Check if the repository already exists locally
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

echo "Monitoring repository at $REPO_DIR for changes..."

# Start monitoring the repository for changes
while true; do
  # Get the current commit hash in the local repository
  LOCAL_COMMIT_HASH=$(git rev-parse HEAD)

  # Fetch the latest commit hash from the remote repository without checking out files
  REMOTE_COMMIT_HASH=$(git ls-remote origin "$BRANCH" | awk '{print $1}')

  # Compare the local commit hash with the remote commit hash
  if [ "$LOCAL_COMMIT_HASH" != "$REMOTE_COMMIT_HASH" ]; then
    echo "Changes detected, pulling latest updates..."
    git pull origin "$BRANCH" || { echo "Failed to pull latest changes"; continue; }

    # Execute the desired script after git pull
    echo "Executing the script after git pull..."
    bash "$SCRIPT_TO_RUN"
  else
    echo "No changes detected, waiting for new commits..."
  fi

  # Sleep for a while before checking again (e.g., every 30 seconds)
  sleep 30
done
