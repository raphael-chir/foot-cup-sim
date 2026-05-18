import { useEffect, useRef, useState } from 'react'
import { api } from './api'
import KnockoutBracket from './KnockoutBracket'
import {
  DEFAULT_PARALLEL_CONFIG,
  DEFAULTS,
  EVENT_ICONS,
  FLAG_BY_CODE,
  NEXT_PHASE,
  PHASES,
  TEXT,
  UI_STORAGE_KEY,
  VISIBLE_PHASE_SETTINGS,
} from './config'

function loadStoredState() {
  try {
    const raw = localStorage.getItem(UI_STORAGE_KEY)
    return raw ? JSON.parse(raw) : {}
  } catch {
    return {}
  }
}

function getPhaseByKey(key) {
  return PHASES.find(phase => phase.key === key)
}

function getPhaseIndex(key) {
  return Math.max(0, PHASES.findIndex(phase => phase.key === key))
}

function getNextPhaseIndexFromBracket(knockout) {
  if (!knockout.length) return 0

  for (let i = 1; i < PHASES.length; i++) {
    const phase = PHASES[i]
    const matches = knockout.filter(match => match.phase === phase.key)

    if (!matches.length) return i
    if (matches.some(match => match.status !== 'COMPLETED')) return i
  }

  return PHASES.length - 1
}

export default function App() {
  const stored = loadStoredState()

  const [isRunning, setIsRunning] = useState(false)
  const [isResetting, setIsResetting] = useState(false)
  const [statusMessage, setStatusMessage] = useState(stored.statusMessage || 'Ready')

  const [currentPhaseIndex, setCurrentPhaseIndex] = useState(stored.currentPhaseIndex ?? 0)

  const [matchDurationSeconds, setMatchDurationSeconds] = useState(
    stored.matchDurationSeconds || DEFAULTS.matchDurationSeconds
  )
  const matchDurationRef = useRef(stored.matchDurationSeconds || DEFAULTS.matchDurationSeconds)

  const [parallelConfig, setParallelConfig] = useState({
    ...DEFAULT_PARALLEL_CONFIG,
    ...(stored.parallelConfig || {}),
  })

  const [virtualSpectators, setVirtualSpectators] = useState(
    stored.virtualSpectators ?? DEFAULTS.virtualSpectators
  )

  const [liveMatches, setLiveMatches] = useState([])
  const [selectedLiveIndex, setSelectedLiveIndex] = useState(stored.selectedLiveIndex || 0)
  const [liveMatch, setLiveMatch] = useState(null)

  const [events, setEvents] = useState([])
  const [goals, setGoals] = useState([])
  const [standings, setStandings] = useState([])
  const [topScorers, setTopScorers] = useState([])

  const [goalAnimation, setGoalAnimation] = useState(null)

  const [knockoutMatches, setKnockoutMatches] = useState([])
  const [champion, setChampion] = useState(stored.champion || null)
  const [showChampion, setShowChampion] = useState(stored.showChampion || false)

  const [elapsedSeconds, setElapsedSeconds] = useState(0)

  const [totals, setTotals] = useState(stored.totals || {
    success: 0,
    errors: 0,
    reads: 0,
    writes: 0,
  })

  const [rates, setRates] = useState({
    tps: 0,
    readPerSecond: 0,
    writePerSecond: 0,
  })

  const previousGoalCountRef = useRef(0)
  const previousMatchIdRef = useRef(null)
  const stopRequestedRef = useRef(false)
  const simulationStartedAtRef = useRef(stored.simulationStartedAt || null)
  const requestWindowRef = useRef([])

  const currentPhase = PHASES[currentPhaseIndex] || PHASES[0]

  const startButtonLabel = isRunning
    ? currentPhase.runningLabel
    : liveMatches.length
      ? `Reprendre ${currentPhase.label}`
      : currentPhase.buttonLabel

  useEffect(() => {
    const state = {
      currentPhaseIndex,
      matchDurationSeconds,
      parallelConfig,
      virtualSpectators,
      selectedLiveIndex,
      statusMessage,
      totals,
      champion,
      showChampion,
      simulationStartedAt: simulationStartedAtRef.current,
    }

    localStorage.setItem(UI_STORAGE_KEY, JSON.stringify(state))
  }, [
    currentPhaseIndex,
    matchDurationSeconds,
    parallelConfig,
    virtualSpectators,
    selectedLiveIndex,
    statusMessage,
    totals,
    champion,
    showChampion,
  ])

  useEffect(() => {
    matchDurationRef.current = matchDurationSeconds
  }, [matchDurationSeconds])

  useEffect(() => {
    const interval = setInterval(() => {
      if (!simulationStartedAtRef.current) {
        setElapsedSeconds(0)
        return
      }

      setElapsedSeconds(Math.floor((Date.now() - simulationStartedAtRef.current) / 1000))
    }, 1000)

    return () => clearInterval(interval)
  }, [])

  useEffect(() => {
    const interval = setInterval(() => {
      const now = Date.now()
      const recent = requestWindowRef.current.filter(item => now - item.ts <= 10000)
      requestWindowRef.current = recent

      const lastSecond = recent.filter(item => now - item.ts <= 1000)

      setRates({
        tps: lastSecond.length,
        readPerSecond: lastSecond.filter(item => item.kind === 'read').length,
        writePerSecond: lastSecond.filter(item => item.kind === 'write').length,
      })
    }, 1000)

    return () => clearInterval(interval)
  }, [])

  async function track(kind, fn) {
    try {
      const result = await fn()

      requestWindowRef.current.push({
        ts: Date.now(),
        kind,
        success: true,
      })

      setTotals(current => ({
        ...current,
        success: current.success + 1,
        reads: current.reads + (kind === 'read' ? 1 : 0),
        writes: current.writes + (kind === 'write' ? 1 : 0),
      }))

      return result
    } catch (err) {
      requestWindowRef.current.push({
        ts: Date.now(),
        kind,
        success: false,
      })

      setTotals(current => ({
        ...current,
        errors: current.errors + 1,
        reads: current.reads + (kind === 'read' ? 1 : 0),
        writes: current.writes + (kind === 'write' ? 1 : 0),
      }))

      throw err
    }
  }

  async function refreshData() {
    const matches = await track('read', () => api.getLiveMatches())
    const standingsData = await track('read', () => api.getStandings())
    const knockout = await track('read', () => api.getKnockoutBracket())
    const scorers = await track('read', () => api.getTopScorers())

    setLiveMatches(matches)
    setStandings(standingsData)
    setKnockoutMatches(knockout)
    setTopScorers(scorers)

    if (knockout.length > 0) {
      const nextIndex = getNextPhaseIndexFromBracket(knockout)
      setCurrentPhaseIndex(nextIndex)
    }

    const finalMatch = knockout.find(
      match => match.phase === 'FINAL' && match.status === 'COMPLETED'
    )

    if (finalMatch) {
      setChampion(finalMatch.winner_team)
      setShowChampion(true)
      setStatusMessage(`${finalMatch.winner_team} wins the World Cup!`)
    }

    return {
      liveMatches: matches,
      knockout,
    }
  }

  useEffect(() => {
    async function load() {
      try {
        await refreshData()
      } catch (err) {
        console.error('Polling error', err)
      }
    }

    load()

    const interval = setInterval(load, 1000)

    return () => clearInterval(interval)
  }, [])

  useEffect(() => {
    if (!liveMatches.length) {
      setLiveMatch(null)
      setEvents([])
      setGoals([])
      setSelectedLiveIndex(0)
      return
    }

    if (selectedLiveIndex >= liveMatches.length) {
      setSelectedLiveIndex(0)
      return
    }

    setLiveMatch(liveMatches[selectedLiveIndex])
  }, [liveMatches, selectedLiveIndex])

  useEffect(() => {
    async function loadMatchData() {
      try {
        if (!liveMatch) {
          setEvents([])
          setGoals([])
          previousGoalCountRef.current = 0
          previousMatchIdRef.current = null
          return
        }

        const eventsData = await track('read', () => api.getLatestEvents(liveMatch.match_id))
        const goalsData = await track('read', () => api.getGoalEvents(liveMatch.match_id))

        setEvents(eventsData)
        setGoals(goalsData)

        if (previousMatchIdRef.current !== liveMatch.match_id) {
          previousMatchIdRef.current = liveMatch.match_id
          previousGoalCountRef.current = goalsData.length
          return
        }

        if (goalsData.length > previousGoalCountRef.current) {
          const lastGoal = goalsData[goalsData.length - 1]
          setGoalAnimation(lastGoal)

          setTimeout(() => setGoalAnimation(null), 1600)
        }

        previousGoalCountRef.current = goalsData.length
      } catch (err) {
        console.error('Match data error', err)
      }
    }

    loadMatchData()
  }, [liveMatch])

  const standingsByGroup = standings.reduce((acc, row) => {
    if (!acc[row.group_name]) acc[row.group_name] = []
    acc[row.group_name].push(row)
    return acc
  }, {})

  const liveTeamCodes = new Set(
    liveMatches.flatMap(match => [match.home_code, match.away_code])
  )

  const homeGoals = goals.filter(goal => goal.team_code === liveMatch?.home_code)
  const awayGoals = goals.filter(goal => goal.team_code === liveMatch?.away_code)

  const totalRequests = totals.success + totals.errors

  function formatElapsed(seconds) {
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = seconds % 60
    return `${String(minutes).padStart(2, '0')}:${String(remainingSeconds).padStart(2, '0')}`
  }

  function getTickIntervalMs() {
    return Math.max(100, Math.round((matchDurationRef.current * 1000) / 90))
  }

  function updateParallelConfig(phase, value) {
    setParallelConfig(current => ({
      ...current,
      [phase]: Number(value),
    }))
  }

  async function getNextGroupBatch() {
    const scheduled = await track('read', () => api.getScheduledGroupMatches())

    const byGroup = scheduled.reduce((acc, match) => {
      if (!acc[match.group_name]) acc[match.group_name] = []
      acc[match.group_name].push(match)
      return acc
    }, {})

    const groups = Object.keys(byGroup).sort()
    const selected = []

    for (const group of groups) {
      if (selected.length >= parallelConfig.GROUP) break
      selected.push(...byGroup[group].slice(0, 2))
      if (selected.length >= parallelConfig.GROUP) break
    }

    return selected.slice(0, parallelConfig.GROUP)
  }

  async function runAudienceReads() {
    const tasks = Array.from({ length: virtualSpectators }, () =>
      track('read', () => api.getAudienceReadSample())
    )

    await Promise.allSettled(tasks)
  }

  async function finishCurrentPhase(phaseKey) {
    const phase = getPhaseByKey(phaseKey)
    const nextPhase = NEXT_PHASE[phaseKey]

    if (phaseKey === 'GROUP') {
      await track('write', () => api.generateRound32())
      setStatusMessage(phase.completedLabel)
      return
    }

    if (nextPhase) {
      await track('write', () =>
        api.generateNextKnockoutRound(phaseKey, nextPhase)
      )

      setStatusMessage(phase.completedLabel)
      return
    }

    const knockout = await track('read', () => api.getKnockoutBracket())

    const finalMatch = knockout.find(
      match => match.phase === 'FINAL' && match.status === 'COMPLETED'
    )

    if (finalMatch) {
      setChampion(finalMatch.winner_team)
      setShowChampion(true)
      setStatusMessage(`${finalMatch.winner_team} wins the World Cup!`)
    } else {
      setStatusMessage('Tournoi terminé')
    }
  }

  async function runPhase(phaseIndex) {
    const phaseConfig = PHASES[phaseIndex]
    const phase = phaseConfig.key
    const parallel = parallelConfig[phase]

    setCurrentPhaseIndex(phaseIndex)
    setStatusMessage(phaseConfig.runningLabel)

    while (!stopRequestedRef.current) {
      let nextMatches = []

      if (phase === 'GROUP') {
        nextMatches = await getNextGroupBatch()
      } else {
        nextMatches = await track('read', () =>
          api.getNextScheduledMatchesByPhase(phase, parallel)
        )
      }

      if (!nextMatches.length) break

      const matchIds = nextMatches.map(match => match.id)

      await Promise.all(
        matchIds.map(matchId => track('write', () => api.startMatch(matchId)))
      )

      await tickLiveMatches(matchIds)
    }

    if (!stopRequestedRef.current) {
      await finishCurrentPhase(phase)

      const { knockout } = await refreshData()
      const nextIndex = getNextPhaseIndexFromBracket(knockout)

      setCurrentPhaseIndex(
        phase === 'GROUP'
          ? getPhaseIndex('ROUND_32')
          : nextIndex
      )
    }
  }

  async function tickLiveMatches(initialMatchIds = []) {
    let currentLive = await track('read', () => api.getLiveMatches())
    let liveIds = currentLive.length
      ? currentLive.map(match => match.match_id)
      : initialMatchIds

    while (liveIds.length > 0 && !stopRequestedRef.current) {
      await Promise.all(
        liveIds.map(async matchId => {
          try {
            await track('write', () => api.generateMatchTick(matchId))
          } catch {
            // Match may already be completed.
          }
        })
      )

      await runAudienceReads()

      currentLive = await track('read', () => api.getLiveMatches())
      setLiveMatches(currentLive)
      liveIds = currentLive.map(match => match.match_id)

      await new Promise(resolve => setTimeout(resolve, getTickIntervalMs()))
    }
  }

  async function startTournament() {
    if (isRunning || isResetting) return

    stopRequestedRef.current = false

    if (!simulationStartedAtRef.current) {
      simulationStartedAtRef.current = Date.now()
      setElapsedSeconds(0)
    }

    setIsRunning(true)

    try {
      const { liveMatches: existingLive, knockout } = await refreshData()

      if (existingLive.length > 0) {
        setStatusMessage(`Reprise ${currentPhase.label}`)
        await tickLiveMatches(existingLive.map(match => match.match_id))
      }

      const phaseIndex = knockout.length
        ? getNextPhaseIndexFromBracket(knockout)
        : currentPhaseIndex

      await runPhase(phaseIndex)
    } catch (err) {
      console.error('Tournament error', err)
      setStatusMessage('Tournament error')
    } finally {
      setIsRunning(false)
    }
  }

  async function resetTournament() {
    stopRequestedRef.current = true
    setIsResetting(true)
    setIsRunning(false)
    setStatusMessage('Resetting tournament...')

    try {
      setMatchDurationSeconds(DEFAULTS.matchDurationSeconds)
      matchDurationRef.current = DEFAULTS.matchDurationSeconds
      setVirtualSpectators(DEFAULTS.virtualSpectators)
      setParallelConfig(DEFAULT_PARALLEL_CONFIG)
      setCurrentPhaseIndex(0)

      setLiveMatches([])
      setLiveMatch(null)
      setEvents([])
      setGoals([])
      setSelectedLiveIndex(0)
      setStandings([])
      setTopScorers([])
      setGoalAnimation(null)
      setElapsedSeconds(0)
      setKnockoutMatches([])
      setChampion(null)
      setShowChampion(false)

      setTotals({
        success: 0,
        errors: 0,
        reads: 0,
        writes: 0,
      })

      setRates({
        tps: 0,
        readPerSecond: 0,
        writePerSecond: 0,
      })

      requestWindowRef.current = []
      previousGoalCountRef.current = 0
      previousMatchIdRef.current = null
      simulationStartedAtRef.current = null
      localStorage.removeItem(UI_STORAGE_KEY)

      await track('write', () => api.resetTournament())

      const standingsData = await track('read', () => api.getStandings())
      setStandings(standingsData)

      setStatusMessage('Tournament reset')
    } catch (err) {
      console.error('Reset error', err)
      setStatusMessage('Reset error')
    } finally {
      setTimeout(() => setIsResetting(false), 500)
    }
  }

  return (
    <div className="min-h-screen bg-slate-950 text-white p-6">
      <div className="max-w-[1600px] mx-auto">
        <div className="mb-8 flex justify-between items-end">
          <div className="flex items-center gap-5">
            <WorldCupMark />

            <div>
              <h1 className="text-5xl font-bold tracking-tight">
                {TEXT.title}
              </h1>
              <p className="text-slate-400 mt-2 text-lg">
                {TEXT.subtitle}
              </p>
            </div>
          </div>

          <div className="text-right">
            <div className="text-sm text-slate-500">Status</div>
            <div className="text-lg font-semibold text-blue-300 max-w-[520px]">
              {statusMessage}
            </div>
          </div>
        </div>

        <div className="grid grid-cols-12 gap-6">
          <div className="relative col-span-7 rounded-[32px] bg-slate-900 border border-slate-800 p-8 shadow-2xl overflow-hidden">
            {goalAnimation && (
              <div className="absolute inset-0 z-20 flex items-center justify-center bg-black/60 animate-pulse">
                <div className="rounded-[40px] bg-emerald-500 px-12 py-8 text-center shadow-2xl">
                  <div className="text-7xl font-black tracking-tight">GOAL!</div>
                  <div className="text-2xl mt-2">
                    ⚽ {goalAnimation.player_name} ({goalAnimation.player_position}) — {goalAnimation.minute}'
                  </div>
                </div>
              </div>
            )}

            <div className="flex items-center justify-between mb-8">
              <div>
                <h2 className="text-2xl font-semibold">{TEXT.liveMatch}</h2>
                <div className="text-slate-400 text-sm mt-2">
                  Match {liveMatches.length ? selectedLiveIndex + 1 : 0} / {liveMatches.length}
                </div>
              </div>

              <div className="flex items-center gap-3">
                <button
                  onClick={() => setSelectedLiveIndex(index => Math.max(0, index - 1))}
                  disabled={!liveMatches.length || selectedLiveIndex === 0}
                  className="px-3 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 disabled:opacity-40"
                >
                  Previous
                </button>

                <button
                  onClick={() =>
                    setSelectedLiveIndex(index =>
                      Math.min(liveMatches.length - 1, index + 1)
                    )
                  }
                  disabled={!liveMatches.length || selectedLiveIndex >= liveMatches.length - 1}
                  className="px-3 py-2 rounded-xl bg-slate-800 hover:bg-slate-700 disabled:opacity-40"
                >
                  Next
                </button>

                <div className="px-4 py-2 rounded-full bg-red-500/20 text-red-400 font-medium">
                  {liveMatch ? 'LIVE' : 'WAITING'}
                </div>
              </div>
            </div>

            {showChampion && champion ? (
              <ChampionPanel champion={champion} />
            ) : liveMatch ? (
              <>
                <div className="grid grid-cols-3 items-start gap-4">
                  <TeamScoreBlock
                    code={liveMatch.home_code}
                    name={liveMatch.home_team}
                    goals={homeGoals}
                  />

                  <div className="text-center">
                    <div className="text-slate-400 mb-3 text-lg">
                      {liveMatch.minute >= 90 ? "90'" : `${liveMatch.minute}'`}
                    </div>

                    <div className="text-8xl font-bold tracking-tight">
                      {liveMatch.home_score} - {liveMatch.away_score}
                    </div>
                  </div>

                  <TeamScoreBlock
                    code={liveMatch.away_code}
                    name={liveMatch.away_team}
                    goals={awayGoals}
                  />
                </div>

                <div className="mt-8 space-y-3">
                  {events.map(event => (
                    <div
                      key={event.id}
                      className="rounded-2xl bg-slate-800 px-5 py-4 flex justify-between gap-4"
                    >
                      <span>
                        <span className="mr-2">
                          {EVENT_ICONS[event.event_type] || '•'}
                        </span>
                        {event.description}
                      </span>

                      <span className="text-slate-400">
                        {event.minute}'
                      </span>
                    </div>
                  ))}
                </div>
              </>
            ) : (
              <div className="rounded-3xl bg-slate-800 p-8 text-slate-300 text-lg">
                <div className="font-semibold mb-3">
                  {TEXT.noLiveMatch}
                </div>
                <div className="text-slate-400">
                  {TEXT.knockoutPlan}
                </div>
              </div>
            )}
          </div>

          <div className="col-span-5 rounded-[32px] bg-slate-900 border border-slate-800 p-8 shadow-2xl">
            <h2 className="text-2xl font-semibold mb-8">
              {TEXT.audienceLoad}
            </h2>

            <div className="grid grid-cols-2 gap-4">
              <Metric title="Elapsed" value={formatElapsed(elapsedSeconds)} />
              <Metric title="Live matches" value={liveMatches.length} />
              <Metric title="TPS" value={rates.tps} />
              <Metric title="Success" value={totals.success} />
              <Metric title="Errors" value={totals.errors} />
              <Metric title="Top scorer" value={topScorers[0]?.goals || 0} />
            </div>

            <div className="mt-4">
              <TopScorersPanel scorers={topScorers} />
            </div>

            <div className="mt-8 grid grid-cols-2 gap-4">
              <NumberInput
                label="Match duration seconds"
                value={matchDurationSeconds}
                min={10}
                max={120}
                onChange={setMatchDurationSeconds}
              />

              <NumberInput
                label="Virtual spectators"
                value={virtualSpectators}
                min={0}
                max={64}
                onChange={setVirtualSpectators}
              />
            </div>

            <div className="mt-8 grid grid-cols-2 gap-4">
              {PHASES
                .filter(phase => VISIBLE_PHASE_SETTINGS.includes(phase.key))
                .map(phase => (
                  <NumberInput
                    key={phase.key}
                    label={phase.label}
                    value={parallelConfig[phase.key]}
                    min={1}
                    max={32}
                    onChange={value => updateParallelConfig(phase.key, value)}
                  />
                ))}
            </div>

            <div className="flex gap-4 mt-10">
              <button
                onClick={startTournament}
                disabled={isRunning || isResetting}
                className="flex-1 rounded-2xl bg-blue-600 hover:bg-blue-500 transition p-4 font-semibold disabled:opacity-50"
              >
                {startButtonLabel}
              </button>

              <button
                onClick={resetTournament}
                disabled={isResetting}
                className={`flex-1 rounded-2xl transition p-4 font-semibold ${
                  isResetting
                    ? 'bg-red-400 animate-pulse'
                    : 'bg-red-600 hover:bg-red-500'
                }`}
              >
                {isResetting ? TEXT.resetting : TEXT.reset}
              </button>
            </div>
          </div>

          <div className="col-span-12 rounded-[32px] bg-slate-900 border border-slate-800 p-7 shadow-2xl">
            {knockoutMatches.length > 0 ? (
              <>
                <h2 className="text-3xl font-bold mb-8">
                  {TEXT.knockoutStage}
                </h2>

                <KnockoutBracket matches={knockoutMatches} />
              </>
            ) : (
              <>
                <h2 className="text-2xl font-semibold mb-6">
                  {TEXT.groupStandings}
                </h2>

                <div className="grid grid-cols-4 gap-5">
                  {Object.entries(standingsByGroup)
                    .sort(([a], [b]) => a.localeCompare(b))
                    .map(([group, teams]) => (
                      <div
                        key={group}
                        className="rounded-3xl bg-slate-800 p-5"
                      >
                        <div className="font-bold text-xl mb-4">
                          Groupe {group}
                        </div>

                        <div className="space-y-3">
                          {teams.map(team => (
                            <StandingRow
                              key={team.team_code}
                              team={team.team_name}
                              code={team.team_code}
                              pts={team.points}
                              gd={team.goal_difference}
                              isLive={liveTeamCodes.has(team.team_code)}
                            />
                          ))}
                        </div>
                      </div>
                    ))}
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

function WorldCupMark() {
  return (
    <div className="w-20 h-20 rounded-[28px] bg-gradient-to-br from-emerald-400 via-blue-500 to-purple-600 flex items-center justify-center shadow-2xl">
      <div className="w-14 h-14 rounded-full bg-slate-950/80 flex items-center justify-center text-3xl">
        🏆
      </div>
    </div>
  )
}

function TeamScoreBlock({ code, name, goals }) {
  return (
    <div className="text-center">
      <div className="text-5xl mb-3">{FLAG_BY_CODE[code] || '🏳️'}</div>
      <div className="text-sm text-slate-500 mb-1">{code}</div>
      <div className="text-3xl font-semibold">{name}</div>

      <div className="mt-5 space-y-2 text-left">
        {goals.map(goal => (
          <div
            key={goal.id}
            className="rounded-xl bg-slate-800 px-3 py-2 text-sm flex justify-between gap-2"
          >
            <span>⚽ {goal.player_name} <span className="text-slate-500">({goal.player_position})</span></span>
            <span className="text-slate-400">{goal.minute}'</span>
          </div>
        ))}
      </div>
    </div>
  )
}

function NumberInput({ label, value, min, max, onChange }) {
  return (
    <div>
      <label className="block text-xs text-slate-400 mb-1">
        {label}
      </label>
      <input
        type="number"
        min={min}
        max={max}
        value={value}
        onChange={event => onChange(Number(event.target.value))}
        className="w-full rounded-xl bg-slate-800 border border-slate-700 px-3 py-2 text-white"
      />
    </div>
  )
}

function Metric({ title, value }) {
  return (
    <div className="rounded-2xl bg-slate-800 p-5">
      <div className="text-slate-400 text-sm">{title}</div>
      <div className="text-3xl font-bold mt-1">{value}</div>
    </div>
  )
}

function TopScorersPanel({ scorers }) {
  return (
    <div className="rounded-2xl bg-slate-800 p-5">
      <div className="text-slate-400 text-sm mb-3">
        {TEXT.topScorers}
      </div>

      <div className="space-y-3">
        {scorers.length ? scorers.slice(0, 3).map((scorer, index) => (
          <div
            key={`${scorer.player_name}-${scorer.team_code}`}
            className="flex items-center justify-between border-b border-slate-700 pb-2 last:border-b-0"
          >
            <div>
              <span className="text-slate-500 mr-2">#{index + 1}</span>
              <span className="mr-2">{FLAG_BY_CODE[scorer.team_code] || '🏳️'}</span>
              <span className="font-semibold">{scorer.player_name}</span>
              <span className="text-slate-500 ml-2">({scorer.player_position})</span>
            </div>

            <div className="font-bold">
              ⚽ {scorer.goals}
            </div>
          </div>
        )) : (
          <div className="text-slate-500">
            {TEXT.noGoals}
          </div>
        )}
      </div>
    </div>
  )
}

function StandingRow({ team, code, pts, gd, isLive }) {
  return (
    <div
      className={`flex justify-between border-b pb-2 gap-3 rounded-xl px-2 py-1 transition ${
        isLive
          ? 'bg-red-500/15 border-red-500/40 animate-pulse'
          : 'border-slate-700'
      }`}
    >
      <span>
        <span className="mr-2">{FLAG_BY_CODE[code] || '🏳️'}</span>
        {team}
        {isLive && (
          <span className="ml-2 text-xs text-red-300 font-bold">
            LIVE
          </span>
        )}
      </span>

      <span className="font-semibold whitespace-nowrap">
        {pts} pts / GD {gd}
      </span>
    </div>
  )
}

function ChampionPanel({ champion }) {
  const confetti = Array.from({ length: 42 })

  return (
    <div className="relative min-h-[540px] rounded-[32px] bg-gradient-to-br from-slate-800 via-slate-900 to-slate-950 border border-blue-500/30 flex items-center justify-center overflow-hidden">
      <div className="absolute inset-0 pointer-events-none">
        {confetti.map((_, index) => (
          <div
            key={index}
            className="absolute text-2xl animate-bounce"
            style={{
              left: `${(index * 23) % 100}%`,
              top: `${(index * 37) % 100}%`,
              animationDelay: `${(index % 12) * 0.12}s`,
              animationDuration: `${1.5 + (index % 5) * 0.25}s`,
            }}
          >
            {['🎉', '✨', '🏆', '⚽', '🎊'][index % 5]}
          </div>
        ))}
      </div>

      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(59,130,246,0.20),transparent_55%)]" />

      <div className="relative z-10 text-center px-8">
        <div className="text-8xl mb-6">🏆</div>

        <div className="text-slate-400 uppercase tracking-[0.3em] text-sm mb-4">
          {TEXT.championTitle}
        </div>

        <div className="text-7xl font-black tracking-tight bg-gradient-to-r from-blue-300 via-emerald-300 to-purple-300 text-transparent bg-clip-text">
          {champion}
        </div>

        <div className="mt-6 text-2xl text-slate-300">
          {TEXT.championSubtitle}
        </div>
      </div>
    </div>
  )
}