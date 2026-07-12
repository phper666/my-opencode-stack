---
description: Switch role: pm | be | fe | qa | designer | oracle
---
/role $ARGUMENTS

Switch current role context. Affects skill loading, output style, and decision scope.

| Role | Agent | Output style | Used for |
|:----|:------|:------------|:---------|
| pm | orchestrator | full narrative | Requirements, PRD, scope decisions |
| be | fixer | caveman lite | Backend implementation, contracts |
| fe | fixer | caveman lite | Frontend implementation, shadcn |
| qa | oracle | standard | Code review, quality gates |
| designer | designer | full narrative | UI/UX design, prototype |
| oracle | oracle | full narrative | Architecture, domain modeling |

Without /role, each pipeline step uses its default role automatically.
