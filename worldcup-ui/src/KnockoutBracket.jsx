import {
  BRACKET_UI,
  FLAG_BY_CODE,
  KNOCKOUT_PHASE_ORDER,
  MATCH_STATUS_LABELS,
  PHASES,
} from './config'

const PHASE_LABELS = Object.fromEntries(
  PHASES.map(phase => [phase.key, phase.label])
)

export default function KnockoutBracket({ matches }) {
  const grouped = matches.reduce((acc, match) => {
    if (!acc[match.phase]) {
      acc[match.phase] = []
    }

    acc[match.phase].push(match)
    return acc
  }, {})

  return (
    <div className="overflow-x-auto">
      <div
        className="flex gap-8"
        style={{ minWidth: BRACKET_UI.minWidth }}
      >
        {KNOCKOUT_PHASE_ORDER.map(phase => (
          <div
            key={phase}
            className={BRACKET_UI.columnWidthClass}
          >
            <h3 className="text-2xl font-bold mb-6 text-center">
              {PHASE_LABELS[phase] || phase}
            </h3>

            <div className="space-y-6">
              {(grouped[phase] || []).map(match => (
                <MatchCard
                  key={match.match_id}
                  match={match}
                />
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

function MatchCard({ match }) {
  const completed = match.status === 'COMPLETED'
  const live = match.status === 'LIVE'

  const cardClass = live
    ? BRACKET_UI.liveCardClass
    : completed
      ? BRACKET_UI.completedCardClass
      : BRACKET_UI.scheduledCardClass

  return (
    <div
      className={`
        rounded-[28px]
        border
        p-3
        shadow-xl
        transition-all
        ${cardClass}
      `}
    >
      <TeamLine
        code={match.home_code}
        team={match.home_team}
        score={match.home_score}
        winner={match.winner_code === match.home_code}
      />

      <div className="my-3 border-t border-slate-700" />

      <TeamLine
        code={match.away_code}
        team={match.away_team}
        score={match.away_score}
        winner={match.winner_code === match.away_code}
      />

      <div className="mt-4 flex justify-between items-center">
        <div className="text-sm text-slate-400">
          Match #{match.match_number}
        </div>

        <StatusBadge status={match.status} />
      </div>
    </div>
  )
}

function TeamLine({
  code,
  team,
  score,
  winner,
}) {
  return (
    <div
      className={`
        flex justify-between items-center
        rounded-2xl p-3
        ${
          winner
            ? 'bg-green-500/10 border border-green-500/30'
            : ''
        }
      `}
    >
      <div className="flex items-center gap-3 min-w-0">
        <div className="text-3xl shrink-0">
          {FLAG_BY_CODE[code] || '🏳️'}
        </div>

        <div
          className={`
            text-lg truncate
            ${
              winner
                ? 'font-bold text-green-300'
                : 'text-white'
            }
          `}
          title={team}
        >
          {team}
        </div>
      </div>

      <div className="text-2xl font-black ml-3">
        {score ?? '-'}
      </div>
    </div>
  )
}

function StatusBadge({ status }) {
  const live = status === 'LIVE'
  const completed = status === 'COMPLETED'

  return (
    <div
      className={`
        text-sm font-semibold px-3 py-1 rounded-full
        ${
          live
            ? 'bg-red-500/20 text-red-300'
            : completed
              ? 'bg-green-500/20 text-green-300'
              : 'bg-slate-700 text-slate-300'
        }
      `}
    >
      {MATCH_STATUS_LABELS[status] || status}
    </div>
  )
}