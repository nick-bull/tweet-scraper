#!/bin/sh

unset colorize output_file \
  twitter_username twitter_term \
  from_input until_input

while test "$#" -gt 0; do
  case "$1" in
    --colorize|-c) colorize=true ;;
    --username|-u) 
      shift
      twitter_username="$1"
    ;;
    --from|-f)
      shift
      from_input="$1"
    ;;
    --until|-u)
      shift
      until_input="$1"
    ;;
    --search-term|-s)
      shift
      twitter_term="$1"
    ;;
    --output|-o)
      shift
      output_file="$1"
    ;;
  esac

  shift
done

if test -n "${twitter_username}"; then
  twitter_command="get_user_tweets_once"
  output_fname="${twitter_username}"
elif test -n "${twitter_term}"; then
  twitter_command="get_term_tweets_once"
  output_fname="${twitter_term}"
else
  echo "tweet-scraper: No username or search term provided"
  exit 1
fi

test -z "$colorize" && colorize=false
test -z "$output_file" && output_file="./${output_fname}.txt"

case "$(uname -s)" in
    Linux*) alias date_cmd=date ;;
    Darwin*) alias date_cmd=gdate ;;
    *)
      echo "Machine not recognised:"
      exit 1
      ;;
esac

retries=10
retry_delay=1
exp_backoff=1.5

get_random() {
  random_number="$(od -An -N2 -tu4 /dev/urandom)"
  echo "$((random_number % ($2 - $1) + $1))"
}
get_random_light_color_format() {
  r="$(get_random 127 255)"
  g="$(get_random 127 255)"
  b="$(get_random 63 127)"
  
  echo "\033[38;2;${r};${g};${b}m"
}

if $colorize; then
  print_format="$(get_random_light_color_format)"
fi

format_reset="\033[m"
print() {
  echo "$print_format$*$format_reset"
}

get_user_tweets_once() {
  twint -u "${twitter_username}" --since "$1" --until "$2"
}

get_term_tweets_once() {
#  if test -n "$1"; then
#    test -n "$args" && args="$args "
#    args="--since $1"
#  fi
#
#  if test -n "$2"; then
#    test -n "$args" && args="$args "
#    args="--until $2"
#  fi
#
#  twint -s "${twitter_term}" $args

  twint -s "${twitter_term}" --since "$1" --until "$2"
}

last_tweet_date="$(date_cmd +'%Y-%m-%d')"
get_tweets() {
  tweet_command="$1"
  from_date="$2"
  until_date="$3"

  current_retries="${retries}"

  while test "${current_retries}" -gt 0; do
    (while :; do
      sleep 15
      x="$((x + 1))"
      
      while_last_tweet_date="$(
        tail -n3 "${output_file}.raw" | awk 'NR == 1 {print $2 " " $3}'
      )"
      echo "Still fetching [$((x * 15))s at ${while_last_tweet_date}]..."
    done) &

    fetch_pid="$!"
    trap - HUP
    trap "kill $fetch_pid" HUP

    "${tweet_command}" "${from_date}" "${until_date}" > "${output_file}.raw"
    fetch_line_count="$(wc -l "${output_file}.raw" | awk '{print $1}')"

    kill "$fetch_pid"

    if test "${fetch_line_count}" -gt 2; then
      head -n2 "${output_file}.raw" >> "${output_file}"
      last_tweet_date="$(tail -n3 "${output_file}.raw" | awk 'NR == 1 {print $2 " " $3}')"

      return 0
    fi

    current_retries="$((current_retries - 1))"

    exp_delay="$(echo "${retry_delay}*${exp_backoff}^(${retries}-${current_retries})" | bc)"
    print "    Retry #$((retries - current_retries)): backoff for ${exp_delay}s"
    sleep "${exp_delay}"

    test "${current_retries}" -eq 0 && return 1
  done
}

until_epoch="$(date_cmd --date="${until_input}" +%s)"

while get_tweets "${twitter_command}" "$from_input" "$last_tweet_date"; do
  print "  $((fetch_line_count - 2)) tweets fetched before ${last_tweet_date}"

  last_tweet_epoch="$(date_cmd --date="${last_tweet_date}" +%s)"

  if test -n "${until_input}" && test "${last_tweet_epoch}" -lt "${until_epoch}"; then
    return 0
  fi
done

print "EXITING"
