{# ---------- mart_cards_daily ---------- #}

{% docs mart_cards_daily %}
Cards created and cards used per calendar day and business segment.
One row per day (every day in `dim_date`) and per industry, plan and country combination that
exists in the account history. Days without activity show 0.
Answers: how many cards are created and used each day, by type of business.

Both counts come from `fct_card_usage_daily`. The segment is the account's segment on that day
(the version valid at the end of the day).

`cards_used` **cannot be summed across days**: a card used on 3 days counts 3 times. For used cards
in a week or month, use `count(distinct card_id)` where `is_used` in `fct_card_usage_daily`.
{% enddocs %}

{% docs mart_cards_daily__cards_created %}
Number of virtual cards created.
Business owner of this definition: Product team.
{% enddocs %}

{% docs mart_cards_daily__cards_used %}
Number of different cards used that day: at least 1 purchase made while the card was ACTIVE.
Business owner of this definition: Product team.
{% enddocs %}


{# ---------- mart_card_activation_monthly ---------- #}

{% docs mart_card_activation_monthly %}
Card activation and usage per month. One row per month, from the month of the first card creation to the
current month.
Answers: how many cards exist, how many of them are active, and how many are used each month.

Each month covers **all cards created up to the end of that month**. A card counts as **active** in a month
when its status was ACTIVE at the end of that month, based on `dim_virtual_cards_history`. So a card can be
active in one month and not active in the next, for example when it is blocked. For the current month, the
latest status so far is used.

Card history is recorded from 2026-11-12. For earlier months, the first known status is assumed, as in the
history dimension.

`activation_rate` cannot be averaged across months. Each month is already a complete picture of all cards.
{% enddocs %}

{% docs mart_card_activation_monthly__year_month %}
The month, as text in the format `YYYY-MM` (for example `2026-11`).
{% enddocs %}

{% docs mart_card_activation_monthly__total_cards %}
Number of cards created up to the end of that month, whatever their status.
{% enddocs %}

{% docs mart_card_activation_monthly__total_active_cards %}
Number of cards whose status was ACTIVE at the end of that month (from the card history), out of all cards
created up to then. For the current month, the latest status so far.
Business owner of this definition: Product team.
{% enddocs %}

{% docs mart_card_activation_monthly__activation_rate %}
`total_active_cards` divided by `total_cards` at the end of that month, between 0 and 1.
Business owner of this definition: Product team.
{% enddocs %}

{% docs mart_card_activation_monthly__cards_used %}
Number of different cards with at least 1 purchase in that month, made while the card was ACTIVE. Each card
counts once per month, even if it was used on many days.
Business owner of this definition: Product team.
{% enddocs %}
