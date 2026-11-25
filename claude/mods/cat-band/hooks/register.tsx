import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

const tick = atom({ plugin: 'cat-band', key: 'tick' } as const, 0)
const isHidden = atom({ plugin: 'cat-band', key: 'isHidden' } as const, false)

const TRACK = 36 // columns the cat walks across

// Walking cat, two leg poses.
const walk = [
  [' /\\_/\\ ', '( o.o )', ' /   \\ '],
  [' /\\_/\\ ', '( o.o )', '  | |  '],
]
// Napping cat, with drifting Zs.
const nap = [
  [' /\\_/\\    z', '( -.- )    ', ' > ^ <     '],
  [' /\\_/\\   Z ', '( -.- )  z ', ' > ^ <     '],
  [' /\\_/\\     ', '( -.- ) Z  ', ' > ^ <     '],
  [' /\\_/\\     ', '( -o- )    ', ' > ^ <     '],
]

function frame(t: number, isWorking: boolean): string[] {
  if (!isWorking) return nap[Math.floor(t / 3) % nap.length] ?? []
  const span = TRACK * 2
  const p = t % span
  const x = p < TRACK ? p : span - p // bounce back and forth
  const pose = walk[t % 2] ?? []
  return pose.map(l => ' '.repeat(x) + l)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    $.clock.every(350, () => update($, tick, n => (n + 1) % 100000))
    await $.command.register({ name: 'cat', description: 'Show or hide the cat above the prompt' })
    return next(e)
  })

  on('command.run', { command: 'cat' }, async $ => {
    const hidden = await update($, isHidden, h => !h)
    return { text: hidden ? 'Cat is hiding. /cat to bring it back.' : 'Cat is back 🐈' }
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey || (await read($, isHidden))) return next(e)
    const t = await read($, tick)
    const { Box, Text } = $.ui.resolve(e)
    const lines = frame(t, e.props.isWorking)
    return (
      <Box flexDirection="column">
        {lines.map((l, i) => (
          <Text key={`l${i}`} color={e.props.isWorking ? 'magenta' : 'cyan'}>
            {l}
          </Text>
        ))}
      </Box>
    )
  })
}
