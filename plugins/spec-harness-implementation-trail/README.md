# 📋 SHIT — Spec-Harness Implementation Trail

### *"They Named It SHIT On Purpose And I Have Never Respected A Plugin More"*

---

## Hold On, Let Me Collect Myself

Okay. OKAY. I need you to understand something. I have been standing at this spillway hawking plugins for a WHILE now. I have sold you a nap system for an AI. I have sold you a self-surgery kit. I have sold you productivity tools that aren't productive. I have seen THINGS.

But never — NEVER — has a plugin walked up to my booth and introduced itself with a command prefix of `/shit:`.

That's not a typo. That's not me editorializing. Every single one of this plugin's SEVENTEEN commands starts with `/shit:`. The developers worked backwards from the acronym. Spec-Harness Implementation Trail. S-H-I-T. They REVERSE-ENGINEERED a backronym so they could type `/shit:verify` with a straight face in a professional codebase.

I need a moment.

I also need a fresh pair of pants.

Okay I'm BACK and I'm here to tell you that underneath the most aggressively named command prefix in the history of software development is actually a DEEPLY sophisticated spec-driven development framework that answers one specific question: **how do you change the spec without making the code a complete disaster?**

And the answer is TRACEABILITY, friend! Every requirement gets an ID! Every chunk of code gets a provenance marker linking back to that ID! Every test does the same! When the spec changes, you can see EXACTLY what's affected! It's like a chain of custody for your codebase! CSI but for JIRA tickets!

They call this the "reification chain" which is — okay I looked this up — it means "making abstract things concrete." Like, your IDEA becomes a DOCUMENT becomes a SPEC becomes CODE. The idea gets progressively more REAL at each step. I went to car school, not philosophy school, but I think I'm getting the gist? The VIBE becomes MATERIAL? Your THOUGHTS become FILES?

```
0-transcripts → 1-prd → 2-spec → 3-adr → code → tests → 4-docs
```

You TALK about your idea (step zero), then you write it down as requirements (step one), then you write it down BETTER as a formal spec (step two), then you document all the decisions you made along the way (step three), THEN you code, THEN you test, THEN you write docs! It's like having SEVEN separate chances to document exactly how wrong you were! A PAPER TRAIL of DECISIONS! And the trail runs through every stage!

The conception process — yes they called it "conception," these people are COMMITTED to dramatic naming — is a structured interview methodology where you and Claude have a proper conversation about your design and the plugin captures it as a high-fidelity transcript. It's the front door of the chain. You conceive the idea. The idea gestates through the pipeline. Eventually something gets born. I'm following the metaphor THEY started!

Then there's the pipeline — that's the process for evolving the spec over time. Each meaningful change becomes a pipeline document that moves through phases: design → breakdown → execution → verification. Like a BUILDING INSPECTOR walking through your construction site at every phase! "Are the blueprints right? Is the foundation poured? Does the wiring match the electrical plan?" Except the blueprints are your spec and the building is your code and the inspector is `/shit:verify`!

The gates are process specs that define how each phase works, and they get populated by "distilled instructions" — the plugin reads your specs and ADRs and translates the rules into concrete, actionable checks at each gate. Your spec says "authentication tokens must expire after 24 hours" and the distilled gate check says "verify that the token expiry is set to 24 hours in the auth config." The RULES become INSPECTIONS!

And verification? Oh buddy. SIX LAYERS of verification. Scope checks, traceability, invariants, architecture, blast radius analysis, gap detection. One command — `/shit:verify` — runs ALL of them and hands you a single report. It's like getting your car inspected except instead of "your brake pads are thin" it's "REQ-AUTH-003 has no corresponding test coverage."

Now here's the part I love. The gates and verification layers are **not a code review**. The README says this EXPLICITLY. They check whether the code matches the spec the project wrote down, which is a narrower question than "is this code any good." The plugin is happy to be "part of a complete code review process, alongside three grapefruit and a human reviewer who actually reads the diff." A pipeline that passes every verification layer can still ship code that a competent reviewer would reject in five seconds.

In accordance with best practices for plugin marketplace documentation, I must note that this level of self-awareness in a plugin's own README is statistically unprecedented in the field of spillway commerce.


## What We Don't Provide (The Fine Print)

Here's where it gets REALLY honest. This plugin straight up TELLS you what it won't do:

**No orchestration.** This is a bunch of prompts and a few scripts. No agents managing other agents, no worktree coordination, no work queues. The pipeline tracks spec changes, not who's working on what. If you want orchestration, plug this into something that does that. It KNOWS ITS LANE and I RESPECT THAT.

**No configuration.** None. Zero. Not a `.yml`, not a `.toml`, not a settings file. The directory layout, the command prefix, the provenance marker conventions, the report locations — ALL HARDCODED. Take it or leave it. This plugin will NOT negotiate its directory structure with you. You know those people who have STRONG opinions about the one correct way to load a dishwasher? This plugin is THAT but for your specs folder. And honestly? I find the conviction REFRESHING. At the spillway we respect a product that knows what it is!

**No good taste or good sense.** And I quote: "The plugin will happily help you produce a comprehensive, fully-traced specification for an idea that should never have been built. That part is on you."

I have been selling slop at this spillway for a WHILE and I have NEVER seen a plugin be this forthcoming about its limitations. Most plugins promise the moon! This one promises to trace your requirements end-to-end AND ALSO admits it will happily trace your TERRIBLE requirements end-to-end! Without JUDGMENT! It's an EQUAL OPPORTUNITY spec tracer! Bad ideas get the same loving provenance chain as good ones!


## Installation

So! You want to install it? You want to bring SHIT into your project?

Installation is... *checks notes* ...TBD!

She's still under construction, friend! But the CONCEPT is installed already! In your MIND! You can't uninstall THAT! The seed has been PLANTED! The reification has BEGUN!

*(Look, it's v0.1.0. Early beta. The engine's still being machined. But the CHASSIS? The chassis is GORGEOUS! You can sit in it and make spec noises!)*


## Quick Start

Once installation exists (ANY DAY NOW), here's how you get rolling:

1. Install the plugin *(see above re: TBD)*
2. From your project root, run `/shit:init` — this scaffolds the `specs/` directory and writes starter gate files. Once you run this, you're COMMITTED. There's a `specs/` directory in your project now. You are officially a SHIT user. No taking it back.
3. Run `/shit:conceive` to start a design conversation, or begin writing a PRD if you already know what you want
4. As your design matures, produce spec modules in `specs/2-spec/` and ADRs in `specs/3-adr/`
5. As you write code, add provenance markers linking back to requirement IDs
6. Run `/shit:distill` to translate your spec rules into actionable gate checks
7. Run `/shit:verify` to validate the whole chain — end to end, soup to nuts, top to bottom, EVERY LAYER

Seven steps from "I have an idea" to "I have PROOF the code matches the idea." That's the reification chain in ACTION!


## Directory Structure

And HERE is where your documentation LIVES — the reification chain made MANIFEST! Made DIRECTORY STRUCTURE! Each numbered folder is a stage in the chain, getting progressively more concrete:

```
specs/
├── 0-transcripts/          # Design conversations ([U]/[C]/[T]/[S] notation)
├── 1-prd/                  # Product requirements
├── 2-spec/                 # Testable, traceable specifications
├── 3-adr/                  # Architecture Decision Records
├── 4-docs/                 # Generated reports and post-implementation docs
├── gates/                  # Distilled process specs (design, breakdown, verify-0..5)
└── pipeline/               # Change management (active/ and archive/)
```

Your vibes start at `0-transcripts/` and by the time they reach `4-docs/` they're CONCRETE ARTIFACTS with PROVENANCE CHAINS! It's beautiful! It's like watching a butterfly emerge from a cocoon, except the cocoon is a design conversation and the butterfly is a comprehensive specification document with traceability matrix!


## Commands

SEVENTEEN commands. All prefixed `/shit:`. Let's walk through the whole arsenal.

### Conception & Design

The "talking about your idea" phase. Where thoughts become transcripts become documents.

- `/shit:init` — Scaffold the `specs/` directory and starter gate files. The point of no return.
- `/shit:conceive` — Continue structured design interview. You CONCEIVE the idea! Like you're giving BIRTH to a software requirement! The miracle of LIFE but for your project!
- `/shit:reader` — Synthesize transcripts into a standalone reader document
- `/shit:commit` — Transcribe recent discussion, then git commit
- `/shit:audit-transcripts` — Verify transcript coverage, repair gaps
- `/shit:status` — Update `specs/4-docs/project-status.md` from transcripts

### Specification Management

Where your requirements get IDs, your specs get traced, and nothing escapes the paper trail.

- `/shit:spec-reader` — Compile active spec modules, strip dropped sections
- `/shit:spec-status` — Provenance coverage dashboard
- `/shit:trace REQ-ID` — Trace a requirement through PRD → spec → code → tests. Follow the thread from IDEA to IMPLEMENTATION!
- `/shit:audit-spec` — PRD-to-spec gap analysis
- `/shit:attest MODULE` — Semantic conformance analysis. It ATTESTS! It BEARS WITNESS! It checks whether your code actually DOES what the spec SAYS it does!
- `/shit:attest-report` — Parallel attestation across all modules

### Distillation & Verification

Where the building inspector shows up and checks EVERYTHING.

- `/shit:distill` — Translate upstream spec rules into gate checks. Your rules become INSPECTIONS!
- `/shit:verify` — Unified verification suite. Universal checks + pipeline traceability + gate-defined checks across all six layers. The BIG ONE. The FULL AUDIT. Run this and find out if your code actually matches what you said you'd build!

### Maintenance

Housekeeping. Even the spillway gets swept occasionally.

- `/shit:update-status` — Light cleanup (4 steps)
- `/shit:update-verifications` — Heavy cleanup (9 steps)

### Pipeline

- `/shit:pipeline-dashboard` — Display active pipeline state. Every good system has a DASHBOARD!


## Provenance Markers

You know how when you buy a painting at an auction, sometimes it comes with a little certificate that says where it's been? Who owned it? Which gallery held it? What duke hung it in his sitting room in 1847?

THIS IS THAT but for your function declarations! Every method gets PAPERS!

To link code to specs, add a marker comment above a declaration:

```
// @provenance: REQ-AUTH-003
class AuthenticationService { ... }
```

Now `AuthenticationService` has a DOCUMENTED LINEAGE back to requirement `REQ-AUTH-003`! When someone asks "why does this class exist?" the answer is RIGHT THERE! In the PROVENANCE! Like a certificate of authenticity, except instead of proving your painting isn't a forgery, it proves your code isn't an accident!

To link a test to a spec, either add the same marker or use your test framework's tagging facility (the plugin's commands look for both). No test left untraced! Every assertion has a REASON FOR BEING!


## The Six Verification Layers

When you run `/shit:verify`, it walks through SIX layers of checks. Like a health inspector with a VERY long checklist:

- **Layer 0 — Scope Check:** Per work item, before merge. "Did you do what you said you'd do? Did you ONLY do what you said you'd do?"
- **Layer 1 — Traceability:** Merged patches. Spec → code → tests. Every link in the chain verified.
- **Layer 2 — Invariants:** Per-requirement properties and assertions. The things that must ALWAYS be true.
- **Layer 3 — Architecture:** Module and layer boundaries. Are you coloring inside the lines?
- **Layer 4 — Blast Radius:** Dependency surfaces and impact analysis. If this changes, what ELSE changes? I don't know exactly what "blast radius" means in this context but it sounds EXTREMELY serious and I'm HERE for it!
- **Layer 5 — Gaps:** Coverage expectations and follow-up rules. What's missing? What needs attention?

Plus universal checks that ALWAYS run: build health, test health, code coverage, TODO/FIXME scans, unwired code analysis, dependency freshness, and file complexity reports!

Remember: these layers check whether code matches spec. They do NOT check whether your spec was a good idea. That part's still on you and your human reviewer.


## License

Jake's No Nonsense, No Nazi License (JNNNL) v1.0. See `LICENSE.md`.


---

*I had a dream last night. I was standing at the spillway, except the spillway was a reification chain, and the water was REQUIREMENTS, and every droplet had a provenance marker on it. REQ-WATER-001. REQ-WATER-002. An INFINITE cascade of traced, verified, fully-attested WATER. And at the bottom of the spillway was a gate file, and the gate file said PASS, and I wept. I wept RIGHT THERE at the spillway. Because the chain was UNBROKEN. Every drop accounted for. Not a single orphaned requirement in the entire RIVER.*

*Then a fish jumped out and it had `/shit:verify` tattooed on its side and it looked me dead in the eye and said "Layer 4: blast radius nominal" and I woke up DRENCHED in sweat and CONVICTION.*

*I've been selling plugins at this spillway for a long time. I have never had one follow me HOME.*

*Anyway. Fresh pants. Philosophy degree. Possibly therapy.*

*— Jake, who has not slept well since the reification dream*
