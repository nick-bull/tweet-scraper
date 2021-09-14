#!/bin/sh

unset username_args

while test "$#" -gt 0; do
  case "$1" in
    --from|-f) 
      shift
      test -n "$username_args" && username_args="$username_args "
      username_args="$username_args--from $1"
    ;;
    --until|-u)
      shift
      test -n "$username_args" && username_args="$username_args "
      username_args="$username_args--until $1"
    ;;
    *)
      test -n "$twitter_usernames" && twitter_usernames="$twitter_usernames "
      twitter_usernames="${twitter_usernames}$1"
    ;;
  esac

  shift
done

while test -n "${twitter_usernames}"; do
  twitter_username="${twitter_usernames%% *}"
  twitter_usernames="${twitter_usernames#${twitter_username}}"
  twitter_usernames="${twitter_usernames# }"

  echo "### Beginning to scrape tweets from '$twitter_username' to 'user-$twitter_username.txt'"
  ./run.sh $username_args --username "$twitter_username" --colorize
done
