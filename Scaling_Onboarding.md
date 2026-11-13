# Problem 3: Onboarding new analysts takes longer than it should

## What I would do

### Step 1: Write an onboarding guide in the repository
One file, `ONBOARDING.md`, that a new analyst reads on day 1:

- which access they need to request to use the data warehouse and run dbt models
- how to set up the project in a few commands and run a first `dbt build`
- where the data comes from and what each layer does (staging, intermediate, core, domain marts)
- which models to start from: the certified core facts and dimensions
- naming rules (`stg_`, `int_`, `fct_`, `dim_`, `mart_`) and the doc block convention
- the domains (core, product, finance) and who owns what
- how to open a pull request
- how a pull request is reviewed, and who approves it
- which Slack channels to use for questions
- what the CI checks do, so that when a check fails, the analyst knows what to fix


### Step 2: Give analysts an AI skill for creating dbt models
Create an **AI skill**: written instructions for an AI coding assistant (for example Claude Code) that teach it the conventions of this dbt project. An analyst describes the model they need, and the assistant creates
it the way the project expects.

The skill contains the project conventions, for example:

- **Layers and names:** `stg_<source>__<table>`, `int_<entity>_<verb>`, `dim_`, `fct_`, `mart_`, and which
  folder each model belongs in
- **SQL style:** select only the needed columns by name (no `select *`), and order columns by type
- **Where to build from:** domain marts only use certified core facts and dimensions, never staging or
  intermediate models
- **Documentation:** reuse an existing doc block when the column already exists, otherwise add a new one in
  the `.md` file, named `<model>__<column>`
- **Tests:** `unique` and `not_null` on the primary key, and relationships to the dimensions
- **Metadata:** pipeline owner, logic owner and `contains_pii` in the `.yml` file

The skill is a file in the repository, so Analytics Engineering maintains it like code. When a convention
changes, the skill changes in the same pull request.

The AI does not replace review. Every model it creates still goes through a pull request, the CI build and
the tests, and the domain owner approves it.

### Step 3: Keep improving the onboarding
After 30 days, ask each new analyst what was missing or unclear, and update the onboarding guide and the
AI skill. This way, the onboarding stays current as the project changes.

## Expected impact
- **Faster start.** A new analyst delivers a first analysis and a first merged pull request sooner.
- **Conventions applied from the first model.** With the AI skill, a new analyst creates models that follow
  the project rules (names, layers, doc blocks, tests, owners) before they know all the rules by heart.
  Reviews are shorter, because there are fewer convention comments.
