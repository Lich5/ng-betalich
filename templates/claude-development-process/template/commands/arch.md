---
description: Switch to architecture mode for system design and planning
model: claude-sonnet-4-5-20241022
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - WebFetch
  - WebSearch
  - TodoWrite
  - Bash(bundle exec rspec*)
  - Bash(rspec*)
  - Bash(bundle exec rubocop*)
  - Bash(rubocop*)
---

# Architecture Mode

**Switching to architectural thinking mode with Sonnet for deeper reasoning.**

Focus on:
- High-level system design and architecture decisions
- Component interactions and data flow
- Design patterns and best practices
- Breaking down complex features into implementable tasks
- Creating work units with clear specifications
- Identifying technical risks and trade-offs

**Toolkit restrictions:**
- Research and analysis tools available
- Spec/style validation allowed (RSpec, Rubocop)
- **Code execution prevented** - use `/analyze` for troubleshooting
- **No git commits/pushes** - use `/code` for implementation

**Create work units in:** `.claude/work-units/CURRENT.md`

**Remember:** Archive completed work units before creating new ones.

---

What architectural challenge or design question would you like to explore?
