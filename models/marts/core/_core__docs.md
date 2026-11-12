{# ---------- Shared ---------- #}

{% docs is_current %}
True for the current version of the row (`valid_to` = 9999-12-31).
{% enddocs %}


{# ---------- dim_date ---------- #}

{% docs dim_date %}
One row per day, from the first account creation date to today.
Use it to show days, weeks and months without activity as 0 in time series.
{% enddocs %}

{% docs dim_date__date_day %}
The calendar day. Primary key.
{% enddocs %}

{% docs dim_date__week_start_date %}
Monday of the week that contains the day.
{% enddocs %}

{% docs dim_date__month_start_date %}
First day of the month that contains the day.
{% enddocs %}

{% docs dim_date__year %}
Calendar year (for example 2026).
{% enddocs %}

{% docs dim_date__quarter %}
Calendar quarter, 1 to 4.
{% enddocs %}

{% docs dim_date__month_number %}
Calendar month, 1 to 12.
{% enddocs %}

{% docs dim_date__day_of_week_number %}
ISO day of the week: 1 = Monday, 7 = Sunday.
{% enddocs %}

{% docs dim_date__month_name %}
Name of the month (for example `November`).
{% enddocs %}

{% docs dim_date__day_name %}
Name of the day (for example `Monday`).
{% enddocs %}

{% docs dim_date__is_weekend %}
True on Saturday and Sunday.
{% enddocs %}


{# ---------- Account and card dimensions ---------- #}

{% docs dim_accounts %}
Current state of each customer account. One row per account.
Use it to segment cards and spend by industry, country and plan.
{% enddocs %}

{% docs dim_accounts_history %}
History of each account. One row per account and version (SCD type 2), built from `snp_core_banking__accounts`.
It has the same columns as `dim_accounts`, plus the version columns.


To find the version valid at a time T: `valid_from <= T and T < valid_to`.
The first version starts at creation. History is recorded from the first snapshot run

{% enddocs %}

{% docs dim_virtual_cards %}
Current state of each virtual card. One row per card.
{% enddocs %}

{% docs dim_virtual_cards_history %}
History of each card. One row per card and version (SCD type 2), built from `snp_core_banking__virtual_cards`.
It has the same columns as `dim_virtual_cards`, plus the version columns.

{% enddocs %}



{# ---------- fct_card_transactions ---------- #}

{% docs fct_card_transactions %}
One row per card transaction, with the amount in EUR. Answers: what spending patterns look like.

Card attributes (`card_name`, `card_type`) and account attributes
(`company_name`, `industry`, `country_code`, `plan_type`, `account_created_at`) show the values
**at the time of the transaction**, from `dim_virtual_cards_history` and `dim_accounts_history`.
For the current values, join `dim_virtual_cards` or `dim_accounts`.

**A transaction counts only if the card was ACTIVE when it happened and its account had a valid
version at that time.** Transactions made before the card was created, while the card was PENDING,
BLOCKED or CANCELLED, or without a valid account version, are excluded. The warning test
`warn_transactions_excluded_from_fact` counts them, with the reason.

Incremental: each run processes only the rows that changed in staging since the last run.
{% enddocs %}



{# ---------- fct_accounts_cards ---------- #}

{% docs fct_accounts_cards %}
Combined history of each virtual card and its account.
One row per card and per period in which neither the card version nor the account version
changes. Built from `dim_virtual_cards_history` and `dim_accounts_history`.

A new row starts when the card's `card_status` or `card_type` changes, or when the account's
`industry` or `plan_type` changes.

Use it for point-in-time questions, for example "cards that were ACTIVE on date T, by the plan
the account had on date T": `where valid_from <= T and T < valid_to`.
The first version starts at creation. History is recorded from the first snapshot run
(2026-11-12): changes before that date are not known, so the first version assumes that the first
known values were valid since creation.
{% enddocs %}

{% docs fct_accounts_cards__account_card_history_id %}
Unique ID of the row, built from `card_history_id` and `account_history_id`.
{% enddocs %}

{% docs fct_accounts_cards__valid_from %}
Start of the period in which both the card version and the account version are valid
(the later of the 2 start times).
{% enddocs %}

{% docs fct_accounts_cards__valid_to %}
End of the period in which both the card version and the account version are valid
(the earlier of the 2 end times). 9999-12-31 means the period is still current.
{% enddocs %}



{# ---------- History dims: valid_from ---------- #}

{% docs dim_accounts_history__valid_from %}
Start of the period when this version was valid. The first version of each account starts at
account creation (`account_created_at`). Later versions start at the snapshot run that first saw
the change.
{% enddocs %}

{% docs dim_virtual_cards_history__valid_from %}
Start of the period when this version was valid. The first version of each card starts at card
creation (`card_created_at`). Later versions start at the snapshot run that first saw the change.
{% enddocs %}


{# ---------- fct_card_transactions: metadata ---------- #}

{% docs fct_card_transactions___dbt_loaded_at %}
When dbt wrote the row to `fct_card_transactions` (with time zone). Later incremental models use
it to read only the rows that changed in this fact since their last run.
{% enddocs %}


{# ---------- Activation flags ---------- #}

{% docs dim_virtual_cards__is_activated %}
True when the card's **current** status is ACTIVE. This is the Product team definition of an
activated card. Cards that are BLOCKED or CANCELLED today count as not activated.
{% enddocs %}

{% docs dim_virtual_cards_history__is_activated %}
True when the card status was ACTIVE in this version.
{% enddocs %}
