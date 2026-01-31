#!/usr/bin/env bash
# Fireflies.ai API wrapper
set -euo pipefail

API_URL="https://api.fireflies.ai/graphql"

[[ -z "${FIREFLIES_API_KEY:-}" ]] && { echo "Error: FIREFLIES_API_KEY not set" >&2; exit 1; }

# Escape string for JSON
json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\n/\\n/g'
}

# GraphQL query helper
gql_query() {
  local query="$1"
  local variables="${2:-{\}}"

  # Escape the query for JSON
  local escaped_query
  escaped_query=$(printf '%s' "$query" | tr '\n' ' ' | sed 's/  */ /g; s/\\/\\\\/g; s/"/\\"/g')

  curl -s -X POST "$API_URL" \
    -H "Authorization: Bearer ${FIREFLIES_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"$escaped_query\", \"variables\": $variables}"
}

# List transcripts with optional filters
cmd_search() {
  local keyword="" from_date="" to_date="" limit=10

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --from) from_date="$2"; shift 2 ;;
      --to) to_date="$2"; shift 2 ;;
      --limit) limit="$2"; shift 2 ;;
      *) keyword="$1"; shift ;;
    esac
  done

  # Build variables JSON manually
  local vars="{\"limit\": $limit"
  [[ -n "$keyword" ]] && vars="$vars, \"keyword\": \"$(json_escape "$keyword")\""
  [[ -n "$from_date" ]] && vars="$vars, \"fromDate\": \"${from_date}T00:00:00.000Z\""
  [[ -n "$to_date" ]] && vars="$vars, \"toDate\": \"${to_date}T23:59:59.999Z\""
  vars="$vars}"

  local query='
    query Search($keyword: String, $fromDate: DateTime, $toDate: DateTime, $limit: Int) {
      transcripts(keyword: $keyword, fromDate: $fromDate, toDate: $toDate, limit: $limit) {
        id
        title
        date
        duration
        participants
        organizer_email
        meeting_attendees {
          displayName
          email
          name
        }
        summary {
          overview
          short_summary
          action_items
          keywords
        }
      }
    }
  '

  gql_query "$query" "$vars"
}

# Get recent transcripts (last 7 days)
cmd_recent() {
  local limit="${1:-10}"
  local from_date
  from_date=$(date -u -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -u -v-7d +%Y-%m-%d 2>/dev/null || date -u +%Y-%m-%d)

  cmd_search --from "$from_date" --limit "$limit"
}

# Get full transcript by ID
cmd_get() {
  local transcript_id="$1"

  local query='
    query GetTranscript($id: String!) {
      transcript(id: $id) {
        id
        title
        date
        duration
        participants
        organizer_email
        host_email
        transcript_url
        audio_url
        meeting_attendees {
          displayName
          email
          name
        }
        speakers {
          id
          name
        }
        sentences {
          speaker_name
          text
          start_time
          end_time
        }
        summary {
          overview
          short_summary
          bullet_gist
          action_items
          keywords
          outline
          topics_discussed
        }
      }
    }
  '

  gql_query "$query" "{\"id\": \"$transcript_id\"}"
}

# Get just the summary for a transcript
cmd_summary() {
  local transcript_id="$1"

  local query='
    query GetSummary($id: String!) {
      transcript(id: $id) {
        id
        title
        date
        duration
        participants
        meeting_attendees {
          displayName
          name
        }
        speakers {
          name
        }
        summary {
          overview
          short_summary
          bullet_gist
          action_items
          keywords
          outline
          topics_discussed
        }
      }
    }
  '

  gql_query "$query" "{\"id\": \"$transcript_id\"}"
}

# List user info
cmd_user() {
  local query='
    query User {
      user {
        user_id
        email
        name
        num_transcripts
        minutes_consumed
      }
    }
  '

  gql_query "$query" "{}"
}

# Help
cmd_help() {
  cat <<EOF
Fireflies.ai CLI

Commands:
  search [keyword] [--from DATE] [--to DATE] [--limit N]
      Search transcripts by keyword (name, company, topic)

  recent [limit]
      Get recent transcripts (last 7 days)

  get <transcript_id>
      Get full transcript with sentences

  summary <transcript_id>
      Get just the summary for a transcript

  user
      Get user info (email, transcript count, minutes)

Examples:
  fireflies.sh search "Alex"
  fireflies.sh search "Opascope" --from "2026-01-18" --to "2026-01-24"
  fireflies.sh recent 5
  fireflies.sh get abc123xyz
  fireflies.sh summary abc123xyz
EOF
}

# Main
cmd="${1:-help}"
shift || true

case "$cmd" in
  search) cmd_search "$@" ;;
  recent) cmd_recent "$@" ;;
  get) cmd_get "$@" ;;
  summary) cmd_summary "$@" ;;
  user) cmd_user ;;
  help|--help|-h) cmd_help ;;
  *) echo "Unknown command: $cmd" >&2; cmd_help; exit 1 ;;
esac
