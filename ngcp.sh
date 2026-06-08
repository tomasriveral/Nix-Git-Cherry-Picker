set -euo pipefail
trap 'echo "Interrupted or failed. Repo may be mid-rebase/cherry-pick." ; exit 1' INT ERR

if [[ $# -eq 0 ]]; then
  echo "Usage: ngcp [mode] [options]"
  echo "Run 'ngcp --help' for more information."
  exit 1
fi

# waits for an internet connection. It pings both Google DNS  and Cloudfare dns in case one of them is down
pings=0
until ping -c1 -W1 1.1.1.1 >/dev/null 2>&1 || \
  ping -c1 -W1 8.8.8.8 >/dev/null 2>&1
  do
  sleep 1
  ((pings++))
  if (( pings > 2 )); then
    echo "No internet connection. Retrying in 1 second..."
  fi
done

CONFIG="$HOME/.config/nix-git-cherry-picker/config.json"

if [[ ! -f "$CONFIG" ]]; then
  echo "Error: Config file not found at $CONFIG"
  echo "Please create it with the necessary settings."
  exit 1
fi

localBranch=$(jq -r '.localBranch' "$CONFIG")
remoteBranch=$(jq -r '.remoteBranch' "$CONFIG")
nixConfigPath=$(jq -r '.nixConfigPath' "$CONFIG")

automatic=0

# if there is the flag --automatic it will fail when merge conflict and tell you to do it manually.
# if there is the flag --no-rebuild it won't rebuild your system to test the new commits
# if there is the flag --continue-with-rebuild it will rebuild if --no-rebuild was set
for flag in "$@"; do
  if [[ "$flag" == "--automatic" ]]; then
    automatic=1
  elif [[ "$flag" == "--help" ]]; then
    echo "Usage: ngcp [mode] [options]"
    echo "Mode:"
    echo " pick <commit 1> <commit2> <...>    Cherry-pick commits for the remote branch."
    echo " pull                               Pulls the changes to the local branch."
    echo "Options:"
    echo "  --automatic                       Exit with no changes if merge conflict and instructs the user to pull manually. This option if for automation."
    exit
  fi
done
# checks if connection


if [[ "$1" == "pick" ]]; then
  if [[ "$#" -lt "2" ]]; then
    echo "Invalid arguments, you must specify commit hashes".
    exit
  fi
  
  #if doesnt exist, just get the branch from the remote
  if ! git -C "$nixConfigPath" checkout "$remoteBranch"; then
    git -C "$nixConfigPath" checkout -b "$remoteBranch" "origin/$remoteBranch"
  fi
  
  for commit in "${@:2}"; do
    if ! [[ $commit =~ "--.*" ]]; then # if not a flag
      if git -C "$nixConfigPath" cherry-pick "$commit"; then
        echo "Applied $commit successfully"
      else
        echo "Cherry-pick of $commit failed."
        echo "Resolve conflicts and run:"
        echo "  git cherry-pick --continue"
        echo
        echo "Type 'y' when done."
    
        while git -C "$nixConfigPath" rev-parse --verify CHERRY_PICK_HEAD >/dev/null 2>&1; do
          read -r answer
          [[ "$answer" == "y" ]] || continue
        done
        echo "Cherry-pick for $commit resolved."
      fi
    fi
  done
  git -C "$nixConfigPath" push --force-with-lease origin "$remoteBranch"
  git -C "$nixConfigPath" checkout "$localBranch"
elif [[ "$1" == "pull" ]]; then
  gitStatus=$(git -C "$nixConfigPath" status --porcelain)
  if [[ -n "$gitStatus" ]]; then
    echo "Git directory is dirty. Please clean it up before running ngcp pull"
    echo "$gitStatus"
    notify-send "Git directory is dirty." "Please clean it up before running ngcp pull\n $gitStatus"
    exit 1
  fi
  if git -C "$nixConfigPath" pull --rebase ; then
    echo "Pull successful"
  else
    if (( automatic )); then
      git -C "$nixConfigPath" rebase --abort || true
      echo "git pull failed. Please run ngcp pull manually"
      notify-send "Git pull failed." "Please run ngcp pull manually"
      exit 1
    else
      echo "Merge conflict detected during pull."
      echo "Resolve conflicts and run:"
      echo "  git rebase --continue"
      echo "Type 'y' when done."
      
      while git -C "$nixConfigPath" rev-parse --verify REBASE_HEAD >/dev/null 2>&1; do
        read -r answer
        [[ "$answer" == "y" ]] || continue
      done
      echo "Pull successful"
    fi
  fi
    git -C "$nixConfigPath" push --force-with-lease origin "$localBranch"
else
  echo "Invalid argument. Please run ngcp --help"
  exit
fi
