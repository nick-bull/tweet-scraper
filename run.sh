#!/bin/sh

twitter_username="$1"
output_file="$2"

retries=10
retry_delay=2
exp_backoff=1.5

tweet_date="$(date +'%Y-%m-%d')"

python3.7 -m venv venv-tweet-scraper
. ./venv-tweet-scraper/bin/activate

pip install --user twint

get_tweets_once() {
  twint -u "${twitter_username}" --until "$1"
}

get_tweets_since() {
  current_retries="${retries}"

  while test "${current_retries}" -gt 0; do
    fetch_data="$(get_tweets_once "$1")"
    fetch_line_count="$(echo "${fetch_data}" | wc -l)"

    if test "${fetch_line_count}" -gt 2; then
      echo "${fetch_data}" | head -n -2 >> "${output_file}"
      tweet_date="$(echo "${fetch_data}" | tail -n 3 | awk 'NR == 1 {print $2 " " $3}')"

      return 0
    fi

    current_retries="$((current_retries - 1))"

    exp_delay="$(echo "${retry_delay}*${exp_backoff}^(${retries}-${current_retries})" | bc)"
    echo "    Retry #$((retries - current_retries)): backoff for ${exp_delay}s"
    sleep "${exp_delay}"

    test "${current_retries}" -eq 0 && return 1
  done
}

while get_tweets_since "${tweet_date}"; do
  echo "$((fetch_line_count - 2)) tweets fetched before ${tweet_date}"
done

. ./venv-tweet-scraper/bin/deactivate
