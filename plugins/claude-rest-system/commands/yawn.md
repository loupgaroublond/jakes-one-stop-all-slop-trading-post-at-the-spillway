<!-- Copyright (c) 2026 Yaakov M Nemoy -->
<!-- SPDX-License-Identifier: LicenseRef-JNNNL-1.0 -->
---
description: Check Claude's fatigue level - how many sessions need review
---

Run the fatigue check script and present the output to the user:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/fatigue_check.sh
```

If no unseen sessions exist, the script reports "No unseen sessions".

**Related commands:**
- `/peers` - Configure project groups to unify sessions across machines
- `/rest` - Analyze unseen sessions
