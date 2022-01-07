#!/usr/bin/env bash

USAGE="usage: $0 query format"
ENDPOINT="https://query.wikidata.org/sparql"

_exec_q(){
  curl "$ENDPOINT" \
    -H "$1" \
    -X POST \
    --data-urlencode query@/dev/stdin
}

main(){
  if [ $# != '2' ]; then
    echo "$USAGE" >&2
    return 1
  fi
  q="$1"
  format="$2"

  if [ "$q" = '-' ]; then
    q='/dev/stdin'
  elif ! [ -f "$q" ]; then
    echo "error: file '$q' is not found">&2
    return 1
  fi

  case "$format" in
    "XML" | "xml" )
      format='application/sparql-results+xml'
      ;;
    "JSON" | "json" )
      format='application/sparql-results+json'
      ;;
    "TSV" | "tsv" )
      format='text/tab-separated-values'
      ;;
    "CSV" | "csv" )
      format='text/csv'
      ;;
    "RDF" | "rdf" | "BINARY" | "binary" )
      format='application/x-binary-rdf-results-table'
      ;;
    *)
      echo 'error: invalid format '"$format" >&2
      return 1
      ;;
  esac

  cat "$1" | _exec_q "Accept: $format"
}
main "${@}"
exit $?
