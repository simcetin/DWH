-- Combined history of each card and its account.
-- One row per card and per period in which neither the card version nor the
-- account version changes. A change in card_status or card_type (card) or in
-- industry or plan_type (account) starts a new row.
--
-- Point-in-time questions become a filter: valid_from <= T and T < valid_to.
{{ config(tags=['core']) }}

with

card_versions as (

    select
        card_history_id,
        card_id,
        account_id,
        card_status,
        card_type,
        valid_from,
        valid_to

    from {{ ref('dim_virtual_cards_history') }}

),

account_versions as (

    select
        account_history_id,
        account_id,
        industry,
        country_code,
        plan_type,
        valid_from,
        valid_to

    from {{ ref('dim_accounts_history') }}

),

-- Pairs of card and account versions whose validity periods overlap.
overlapping_versions as (

    select
        card_versions.card_history_id,
        account_versions.account_history_id,
        card_versions.card_id,
        card_versions.account_id,
        card_versions.card_status,
        card_versions.card_type,
        account_versions.industry,
        account_versions.country_code,
        account_versions.plan_type,
        greatest(card_versions.valid_from, account_versions.valid_from) as valid_from,
        least(card_versions.valid_to, account_versions.valid_to)        as valid_to

    from card_versions
    inner join account_versions
        on  account_versions.account_id = card_versions.account_id
        and account_versions.valid_from < card_versions.valid_to
        and card_versions.valid_from < account_versions.valid_to

),

final as (

    select
        -- ids
        {{ dbt.hash(dbt.concat(['card_history_id', "'-'", 'account_history_id'])) }} as account_card_history_id,
        card_id,
        account_id,
        card_history_id,
        account_history_id,

        -- strings
        card_status,
        card_type,
        industry,
        country_code,
        plan_type,

        -- booleans
        valid_to = cast('9999-12-31' as timestamp) as is_current,

        -- timestamps
        valid_from,
        valid_to

    from overlapping_versions

)

select * from final
