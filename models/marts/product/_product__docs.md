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
