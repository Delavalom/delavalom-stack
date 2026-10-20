/** What the meter shows: one usage figure against its limit. */
export type Reading = { label: string; percent: number; resetsAt?: string }

declare module 'claude-code' {
  interface PluginState {
    'sub-meter': { reading: Reading | null }
  }
}
