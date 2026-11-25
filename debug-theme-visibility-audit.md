# Debug Session: theme-visibility-audit
- Status: [OPEN]
- Issue: Remaining light surfaces, unreadable text and responsive overflow.
- Debug Server: http://127.0.0.1:7777/event
- Log File: .dbg/trae-debug-log-theme-visibility-audit.ndjson

## Hypotheses
| ID | Hypothesis | Likelihood | Effort | Evidence |
|----|------------|------------|--------|----------|
| A | Hardcoded colors bypass active theme | High | Low | Pending widget inspection |
| B | Fixed dimensions overflow with narrow screens and larger text | High | Medium | Pending layout tests |
| C | Profile uses demo fallback instead of authenticated account | High | Low | Pending model checks |

## Reproduction
Render screens with real light/dark themes at 320 and 390 logical pixels.
Inspect section colors, capture Flutter layout exceptions, and verify profile mapping.
Only synthetic account data is used for instrumentation.

## Verification
Pending. Retain instrumentation until user confirms the rendering fixes.
