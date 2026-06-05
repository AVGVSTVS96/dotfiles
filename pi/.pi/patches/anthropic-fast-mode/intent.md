Make pi-ai's Anthropic provider `mergeHeaders` **append and de-duplicate** the
`anthropic-beta` header across header sources instead of overwriting it with
`Object.assign`.

## Why

The Anthropic Messages API gates the Fast Mode `speed: "fast"` body parameter
behind the `anthropic-beta: fast-mode-2026-02-01` header. Without the header the
API returns `400 invalid_request_error: speed: Extra inputs are not permitted`.

`createClient` builds the beta header internally (e.g. for OAuth:
`claude-code-20250219,oauth-2025-04-20,...`) and merges `model.headers` /
`optionsHeaders` on top. Because `mergeHeaders` used `Object.assign`, any caller
that supplies `anthropic-beta` via `options.headers` (the only way an extension
can add the fast-mode beta) would **replace** the internal value — dropping
`oauth-2025-04-20` and breaking Claude Max / OAuth auth.

After this patch, a caller can pass `headers: { "anthropic-beta": "fast-mode-2026-02-01" }`
and it is appended to whatever betas pi already set, deduped, for every auth path
(OAuth, API key, Copilot, Cloudflare). Null-valued headers still delete as before.

## Healing notes

Only `mergeHeaders` changes; behavior for non-`anthropic-beta` keys is identical
to the original `Object.assign` semantics (last writer wins, including `null`).
If pi adds new internal betas the append logic keeps them automatically. Re-anchor
to the `mergeHeaders` function if its surrounding code shifts.
