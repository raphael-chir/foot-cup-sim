export const UI_STORAGE_KEY = 'worldcup-demo-ui-state'

export const DEFAULTS = {
  matchDurationSeconds: 20,
  virtualSpectators: 8,
}

export const PHASES = [
  {
    key: 'GROUP',
    label: 'Groupes',
    buttonLabel: 'Lancer le tournoi',
    runningLabel: 'Groupes en cours',
    completedLabel: 'Groupes terminés — 16èmes prêts',
    defaultParallel: 24,
  },
  {
    key: 'ROUND_32',
    label: '16èmes',
    buttonLabel: 'Lancer les 16èmes',
    runningLabel: '16èmes en cours',
    completedLabel: '16èmes terminés — 8èmes prêts',
    defaultParallel: 16,
  },
  {
    key: 'ROUND_16',
    label: '8èmes',
    buttonLabel: 'Lancer les 8èmes',
    runningLabel: '8èmes en cours',
    completedLabel: '8èmes terminés — quarts prêts',
    defaultParallel: 8,
  },
  {
    key: 'QUARTER',
    label: 'Quarts',
    buttonLabel: 'Lancer les quarts',
    runningLabel: 'Quarts en cours',
    completedLabel: 'Quarts terminés — demies prêtes',
    defaultParallel: 4,
  },
  {
    key: 'SEMI',
    label: 'Demies',
    buttonLabel: 'Lancer les demies',
    runningLabel: 'Demies en cours',
    completedLabel: 'Demies terminées — finale prête',
    defaultParallel: 2,
  },
  {
    key: 'FINAL',
    label: 'Finale',
    buttonLabel: 'Lancer la finale',
    runningLabel: 'Finale en cours',
    completedLabel: 'Tournoi terminé',
    defaultParallel: 1,
  },
]

export const VISIBLE_PHASE_SETTINGS = [
  'GROUP',
  'ROUND_32',
  'ROUND_16',
  'QUARTER',
]

export const DEFAULT_PARALLEL_CONFIG = Object.fromEntries(
  PHASES.map(phase => [phase.key, phase.defaultParallel])
)

export const NEXT_PHASE = {
  GROUP: 'ROUND_32',
  ROUND_32: 'ROUND_16',
  ROUND_16: 'QUARTER',
  QUARTER: 'SEMI',
  SEMI: 'FINAL',
}

export const FLAG_BY_CODE = {
  FRA: '🇫🇷', BRA: '🇧🇷', ARG: '🇦🇷', ENG: '🏴󠁧󠁢󠁥󠁮󠁧󠁿', ESP: '🇪🇸', GER: '🇩🇪',
  POR: '🇵🇹', NED: '🇳🇱', ITA: '🇮🇹', BEL: '🇧🇪', CRO: '🇭🇷', URU: '🇺🇾',
  COL: '🇨🇴', MEX: '🇲🇽', USA: '🇺🇸', MAR: '🇲🇦', JPN: '🇯🇵', SEN: '🇸🇳',
  SUI: '🇨🇭', DEN: '🇩🇰', AUT: '🇦🇹', KOR: '🇰🇷', ECU: '🇪🇨', SRB: '🇷🇸',
  POL: '🇵🇱', SWE: '🇸🇪', NOR: '🇳🇴', TUR: '🇹🇷', CAN: '🇨🇦', AUS: '🇦🇺',
  EGY: '🇪🇬', NGA: '🇳🇬', ALG: '🇩🇿', CMR: '🇨🇲', GHA: '🇬🇭', CIV: '🇨🇮',
  QAT: '🇶🇦', IRN: '🇮🇷', KSA: '🇸🇦', PAR: '🇵🇾', CHI: '🇨🇱', PER: '🇵🇪',
  PAN: '🇵🇦', CRC: '🇨🇷', NZL: '🇳🇿', JAM: '🇯🇲', MLI: '🇲🇱', TUN: '🇹🇳',
}

export const EVENT_ICONS = {
  GOAL: '⚽',
  YELLOW_CARD: '🟨',
  RED_CARD: '🟥',
  CORNER: '🚩',
  FREE_KICK: '🎯',
  OFFSIDE: '🚫',
  FOUL: '💥',
  SUBSTITUTION: '🔁',
  SHOT: '🥅',
  KICKOFF: '▶️',
  HALF_TIME: '⏸️',
  SECOND_HALF: '▶️',
  ADDED_TIME: '⏱️',
  FULL_TIME: '🏁',
}

export const TEXT = {
  title: 'World Cup 2026 Simulator',
  subtitle: 'Real-time tournament simulation',
  liveMatch: 'Live Match',
  audienceLoad: 'Audience / Load',
  groupStandings: 'Classements de groupes',
  knockoutStage: 'Phase finale',
  noLiveMatch: 'Aucun match en live.',
  knockoutPlan: 'Plan phase finale : 16èmes → 8èmes → quarts → demies → finale.',
  topScorers: 'Top 3 buteurs',
  noGoals: 'Aucun but pour le moment',
  championTitle: 'World Cup 2026 Champion',
  championSubtitle: 'wins the tournament',
  reset: 'Reset',
  resetting: 'Resetting...',
}

export const KNOCKOUT_PHASE_ORDER = [
  'ROUND_32',
  'ROUND_16',
  'QUARTER',
  'SEMI',
  'FINAL',
]

export const MATCH_STATUS_LABELS = {
  SCHEDULED: 'À venir',
  LIVE: 'LIVE',
  COMPLETED: 'Terminé',
}

export const BRACKET_UI = {
  minWidth: '1600px',
  columnWidthClass: 'min-w-[300px]',
  liveCardClass: 'bg-red-950 border-red-500 animate-pulse',
  completedCardClass: 'bg-emerald-950 border-emerald-600',
  scheduledCardClass: 'bg-slate-800 border-slate-700',
}