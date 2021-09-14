#!/bin/sh

unset term_args

while test "$#" -gt 0; do
  case "$1" in
    --from|-f) 
      shift
      test -n "$term_args" && term_args="$term_args "
      term_args="$term_args--from $1"
    ;;
    --until|-u)
      shift
      test -n "$term_args" && term_args="$term_args "
      term_args="$term_args--until $1"
    ;;
    *)
      test -n "$twitter_terms" && twitter_terms="$twitter_terms "
      twitter_terms="${twitter_terms}$1"
    ;;
  esac

  shift
done

while test -n "${twitter_terms}"; do
  twitter_term="${twitter_terms%% *}"
  twitter_terms="${twitter_terms#${twitter_term}}"
  twitter_terms="${twitter_terms# }"

  echo "### Beginning to scrape tweets from '$twitter_term' to 'terms-$twitter_term.txt'"
  ./run.sh $term_args --search-term "$twitter_term" --colorize
done
