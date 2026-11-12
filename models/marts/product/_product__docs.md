{# ---------- mart_card_creation ---------- #}

{% docs mart_card_creation %}
Cards created per day, with a running total. One row per day, from the first card creation to
today. Days without new cards show 0.
Answers: how many virtual cards are being created over time.
{% enddocs %}

{% docs mart_card_creation__cards_created %}
Number of virtual cards created.
{% enddocs %}

{% docs mart_card_creation__cumulative_cards_created %}
Total number of cards created up to and including this day.
{% enddocs %}


{# ---------- mart_card_activation ---------- #}

{% docs mart_card_activation %}
Card creation, activation and usage by creation month and business segment.
One row per creation month, industry, country, plan and card type.
Answers: which types of businesses create and use cards most, and what the activation and usage
rates are.

Rates cannot be summed or averaged across rows. To combine rows (for example all countries),
sum the counts and divide again.
{% enddocs %}

{% docs mart_card_activation__created_month %}
First day of the month in which the cards were created.
{% enddocs %}

{% docs mart_card_activation__activated_cards %}
Number of activated cards (current status ACTIVE).
{% enddocs %}

{% docs mart_card_activation__cards_with_transactions %}
Number of cards with at least 1 counted transaction (made while the card was ACTIVE).
{% enddocs %}

{% docs mart_card_activation__activated_cards_with_transactions %}
Number of activated cards that have at least 1 transaction.
{% enddocs %}

{% docs mart_card_activation__activation_rate %}
Activated cards ÷ cards created. Between 0 and 1.
{% enddocs %}

{% docs mart_card_activation__usage_rate %}
Activated cards with at least 1 transaction ÷ activated cards. Between 0 and 1.
Null when there are no activated cards.
{% enddocs %}


{# ---------- mart_spending_patterns ---------- #}

{% docs mart_spending_patterns %}
Spending in EUR by transaction month, business segment and merchant category.
One row per transaction month, industry, country, plan and merchant category.
Answers: what spending patterns look like.

`spending_cards` and `spending_accounts` are distinct counts. They cannot be summed across rows.
{% enddocs %}

{% docs mart_spending_patterns__transaction_month %}
First day of the month of the transactions.
{% enddocs %}

{% docs mart_spending_patterns__avg_purchase_eur %}
Average purchase amount in EUR: `gross_spend_eur / purchase_count`. Refunds are not included.
{% enddocs %}

{% docs mart_spending_patterns__spending_cards %}
Number of different cards with at least 1 transaction.
{% enddocs %}

{% docs mart_spending_patterns__spending_accounts %}
Number of different accounts with at least 1 transaction.
{% enddocs %}


{# ---------- mart_card_usage_frequency ---------- #}

{% docs mart_card_usage_frequency %}
Usage frequency of active cards by month and business segment.
One row per month, industry, country and plan, from the first to the last transaction month.
Answers: how often active cards are used.

Active cards are cards with current status ACTIVE that were created before the end of the month.
Transactions on cards that are BLOCKED or CANCELLED today are not counted.
{% enddocs %}

{% docs mart_card_usage_frequency__activity_month %}
First day of the month being measured.
{% enddocs %}

{% docs mart_card_usage_frequency__active_cards %}
Number of active cards (current status ACTIVE) created before the end of the month.
{% enddocs %}

{% docs mart_card_usage_frequency__transactions_on_active_cards %}
Number of transactions in the month on the active cards.
{% enddocs %}

{% docs mart_card_usage_frequency__usage_frequency %}
Transactions per active card in the month: `transactions_on_active_cards / active_cards`.
{% enddocs %}


{# ---------- mart_spending_patterns: counts ---------- #}

{% docs mart_spending_patterns__purchase_count %}
Number of purchases (transactions with a positive amount).
{% enddocs %}

{% docs mart_spending_patterns__refund_count %}
Number of refunds (transactions with a negative amount).
{% enddocs %}


{# ---------- mart_spending_patterns: amounts ---------- #}

{% docs mart_spending_patterns__transaction_count %}
Number of counted transactions (made while the card was ACTIVE), purchases and refunds together.
{% enddocs %}

{% docs mart_spending_patterns__gross_spend_eur %}
Total amount of purchases in EUR, before refunds.
{% enddocs %}

{% docs mart_spending_patterns__refund_amount_eur %}
Total amount of refunds in EUR, as a positive number.
{% enddocs %}

{% docs mart_spending_patterns__net_spend_eur %}
Purchases minus refunds, in EUR (`gross_spend_eur - refund_amount_eur`).
{% enddocs %}
