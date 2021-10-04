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

  output_file="terms-${twitter_term}.txt"

  echo "### Beginning to scrape mentions from '$twitter_term' to '${output_file}'"

  ./run.sh $term_args --search-term "$twitter_term" --colorize
  grep -i "@${twitter_term}" "${output_file}" > "mentions-${twitter_term}.txt"
done
