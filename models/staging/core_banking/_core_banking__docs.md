{% docs core_banking %}
The bank's core banking database: customer accounts, virtual cards and card transactions.
 In this project the tables are loaded from
`seeds/core_banking`.
{% enddocs %}


{# ---------- Tables ---------- #}

{% docs core_banking__accounts %}
One row per customer account.
{% enddocs %}

{% docs core_banking__virtual_cards %}
One row per virtual card. Each card belongs to one account. One account can have multiple cards.
The status is the current status only. It has no history.
{% enddocs %}

{% docs core_banking__transactions %}
One row per card transaction, in the original currency. Negative amounts are refunds.
{% enddocs %}


{# ---------- Accounts ---------- #}

{% docs account_id %}
Unique ID of a customer account.
{% enddocs %}

{% docs company_name %}
Name of the company that owns the account.
{% enddocs %}

{% docs industry %}
Industry of the company, in snake_case (for example `e_commerce`).
{% enddocs %}

{% docs country_code %}
Two-letter ISO 3166 country code of the company (for example `FR`).
{% enddocs %}

{% docs plan_type %}
Subscription plan of the account.

| Value |
|---|
| Basic |
| Essential |
| Smart |
| Premium |
| Business |
| Enterprise |
{% enddocs %}

{% docs account_created_at %}
When the account was created.
{% enddocs %}


{# ---------- Virtual cards ---------- #}

{% docs card_id %}
Unique ID of a virtual card.
{% enddocs %}

{% docs card_name %}
Name the customer gave to the card (for example `Travel`).
{% enddocs %}

{% docs card_status %}
Current status of the card.

| Value | Meaning |
|---|---|
| ACTIVE | The card can be used. |
| PENDING | The card is created but not active yet. |
| BLOCKED | The card is blocked for now. It can be unblocked. |
| CANCELLED | The card is closed for good. |
{% enddocs %}

{% docs card_type %}
Type of the card.

| Value |
|---|
| VIRTUAL |
| INSTANT |
| ONLINE_ADVERTISING |
{% enddocs %}

{% docs card_created_at %}
When the card was created.
{% enddocs %}


{# ---------- Transactions ---------- #}

{% docs transaction_id %}
Unique ID of a card transaction.
{% enddocs %}

{% docs merchant_category %}
Category of the merchant, in snake_case (for example `office_supplies`).
{% enddocs %}

{% docs amount %}
Amount in the original currency (see `currency_code`). Negative amounts are refunds.
{% enddocs %}

{% docs is_refund %}
True when the amount is negative.
{% enddocs %}

{% docs transaction_date %}
Day of the transaction. Use it to join to the daily FX rates (`rate_date`).
{% enddocs %}

{% docs transaction_at %}
Date and time of the transaction.
{% enddocs %}


{# ---------- Ingestion metadata ---------- #}

{% docs _loaded_at %}
When the ingestion step loaded the row into the warehouse (with time zone).
Source freshness checks use this column. In this project `dbt seed` sets it.
{% enddocs %}
