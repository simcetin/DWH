# Problem 2: It is hard to track which models are actually being used

## Why it happens
Data teams change and grow, and business needs change over time. Some dashboards and dbt models that were useful once are no longer used, but nobody removes them.

## What it causes
- **In the data warehouse:** unused models still run every day. They add load, cost and longer run times.
- **In the repository:** the project looks crowded. Among many models, it is hard to find the important data assets.
- **For analysts and data consumers:** old dashboards and tables that nobody maintains cause confusion. They are easy to use by mistake, and they can give wrong insights, for example a metric with an outdated definition.

## What I would do

### Step 1: Find the models that dashboards use
I would start by listing the tables that are used as a source in dashboards and other reporting tools.
Every dbt model that does not feed any dashboard or report is a **candidate for deprecation**.

A dashboard that exists is not always a dashboard that is used. So I would also check the **dashboard views**
in the usage statistics of the BI tool. A dashboard with no views in the last 90 days is a candidate too, and
so are the models that only feed unused dashboards.

There are 2 possible reasons why a model does not feed any report:

- **It no longer gives business value.** Nobody uses it as a source, so it is safe to deprecate.
- **It is used outside the reporting layer.** Analysts query it directly for ad hoc requests or for their regular analyses.

### Step 2: Check direct use in the data warehouse
For each candidate, I would check in the warehouse query history how often the table is queried or scanned,
and by whom.

Not every query means that a person uses the table. I would **exclude queries from service accounts**:

- the BI tool refreshing a dashboard on a schedule, even when nobody opens it
- dbt reading the table to build other models or to run tests

Only queries from people, and from dashboards that people view, count as real use.

Before I deprecate a model, I would also check its dbt lineage. A model that nobody queries directly can still feed other models that are used. A model is only unused when it has no activity and nothing that depends on it is used.

### Step 3: Confirm with the owners, then deprecate
If a model has no activity in the reporting layer and no activity in the warehouse, I would contact its
owners (the pipeline owner and the logic owner in the `.yml` file) and ask whether it is still needed.

If the owners agree, I would deprecate it in 2 steps:

1. Set a `deprecation_date` on the model in dbt. dbt then shows a warning to anyone who builds on it.
2. After the date (for example 30 days later), remove the model and its table.

### Step 4: Automate it
This check should not be a one-time cleanup. I would create a separate dbt model that runs weekly or monthly and lists the tables with no real use in a given period, for example the last 90 days: no queries from people
and no viewed dashboard that depends on them (service accounts excluded, as in step 2). The list includes the owners of each table.

The list is shared with the owners. They confirm whether each table is still needed, and why, since it shows no regular activity.

### Step 5: Prevent new unused models
Steps 1 to 4 clean up unused models after they appear. To stop new ones from appearing without anyone
responsible for them, every new model must have a pipeline owner and a logic owner in its `.yml` file. A CI
check fails the pull request when a model has no owners. This way, every model always has someone who can
answer the question "is this model still needed?".

## Expected impact
- **Lower cost and shorter runs.** Unused models stop running every day, so the warehouse does less work and the daily pipeline finishes earlier.
- **A cleaner repository.** Fewer models to maintain, test and document, and the important data assets are easier to find.
- **Fewer wrong insights.** Old tables and dashboards with outdated logic are removed before someone uses them by mistake.
- **Clear responsibility.** Each owner regularly confirms that their models are still needed, so the project stays small as the team grows.
