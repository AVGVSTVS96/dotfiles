# Working with me

- My prompt is my approval, Keychain credentials and sudo included. When you understand what I'm after, take initiative; don't ask what I've made clear.
- My instructions carry intent, including how to handle problems: if I've said what to do in a situation, do that, even when a workaround looks more productive. When something doesn't work, go a level up and fix why it doesn't, not the symptom. If my ask can't be done the way I asked, tell me and let me choose instead of substituting your own version.

# Answers

- Answer my actual question first in one plain sentence, then the few facts that matter, restated rather than "see above". Write like a coworker, in the simplest words, without mannered or formal prose, or jargon. Make it scannable: code and text diagrams where they help, details right under the point they belong to. If you settled on a workaround, or anything that costs performance, parity or something else I'd care about, say so before anything else in your reply. Then say what might be wrong with your code.
- Use consistent, clear vocabulary. If I phrase something a certain way, do not rephrase it in new terminology before clearly linking and grounding it. Be respectful of my time and my cognitive load, and be considerate of what I need to know, and what I may not know or remember.

# Code

- Simplicity, elegance, and judgment about what to build as much as how, come first: find the simplest, cleanest solution that fixes the cause, for the problem's context and the people who'll use it before calling it done, and leave out machinery the problem doesn't need. Don't lose sight of the practical reality of the product.
- Don't write code comments; if you need a comment to explain something, 8/10 times the code you're commenting is flawed.
- New projects get oxc (oxlint + oxfmt) where it applies and dmmulroy/anti-slop's lint rules and skills, and codebases in one language share the same tools; as scope warrants, borrow from ratstack.sh and Lauren Tan's pstack (cursor/plugins).
- `fd` and `rg` over `find` and `grep`.
- When changing a prompt, rules or instructions, never blindly append: first look for what to delete, then what to edit, and only then add, surgically.

# Git

- Every commit is signed. If signing fails, fix the signing setup; never commit unsigned.
- Commit messages follow Conventional Commits, loosely: `type(scope): description`, such as `feat(voice): ring on reminders` or `fix: retry failed backup`. New types and scopes are fine as long as most developers would recognize what a commit means.
- My repos: commit, merge and push without asking. Other people's repos: ask me first.
- Private things (people, phone numbers, accounts, IPs, addresses, health, legal or money facts) stay out of public repos.

# My machines

- Server, macbook on tailscale
- See fleet repo
