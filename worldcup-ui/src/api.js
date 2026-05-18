const API =
  window.APP_CONFIG?.API_URL ||
  import.meta.env.VITE_API_URL

async function get(path) {
  const response = await fetch(`${API}/${path}`)

  if (!response.ok) {
    const text = await response.text()
    throw new Error(`GET ${path} failed: ${response.status} ${text}`)
  }

  return response.json()
}

async function postRpc(functionName, body = {}) {
  const response = await fetch(`${API}/rpc/${functionName}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
    },
    body: JSON.stringify(body),
  })

  if (!response.ok) {
    const text = await response.text()
    throw new Error(`RPC ${functionName} failed: ${response.status} ${text}`)
  }

  const text = await response.text()
  return text ? JSON.parse(text) : null
}

export const api = {
  getLiveMatches() {
    return get(`v_live_matches?status=eq.LIVE&order=match_number.asc`)
  },

  getLatestEvents(matchId) {
    return get(`v_latest_events?match_id=eq.${matchId}&order=id.desc&limit=6`)
  },

  getGoalEvents(matchId) {
    return get(`v_latest_events?match_id=eq.${matchId}&event_type=eq.GOAL&order=minute.asc`)
  },

  getTopScorers() {
    return get(`v_top_scorers?limit=3`)
  },

  getStandings() {
    return get(`v_group_standings`)
  },

  getScheduledGroupMatches() {
    return get(`v_match_schedule?phase=eq.GROUP&status=eq.SCHEDULED&order=match_number.asc`)
  },

  getNextScheduledMatchesByPhase(phase, limit) {
    return get(`matches?phase=eq.${phase}&status=eq.SCHEDULED&order=match_number.asc&limit=${limit}`)
  },

  getCompletedMatchesByPhase(phase) {
    return get(`matches?phase=eq.${phase}&status=eq.COMPLETED`)
  },

  getAudienceReadSample() {
    return Promise.all([
      get(`v_live_matches?limit=8`),
      get(`v_group_standings?limit=48`),
      get(`v_latest_events?limit=20`),
      get(`v_top_scorers`),
      get(`v_top_scoring_teams`),
      get(`v_top_red_cards`),
    ])
  },

  resetTournament() {
    return postRpc('reset_tournament')
  },

  startMatch(matchId) {
    return postRpc('start_match', {
      p_match_id: matchId,
    })
  },

  generateMatchTick(matchId) {
    return postRpc('generate_match_tick', {
      p_match_id: matchId,
    })
  },

  getKnockoutBracket() {
    return get(`v_knockout_bracket`)
  },

  generateRound32() {
    return postRpc('generate_round_32')
  },

  generateNextKnockoutRound(completedPhase, nextPhase) {
    return postRpc('generate_next_knockout_round', {
      p_completed_phase: completedPhase,
      p_next_phase: nextPhase,
    })
  },
}