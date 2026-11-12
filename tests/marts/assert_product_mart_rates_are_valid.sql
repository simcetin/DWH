-- Rates must be between 0 and 1, and usage frequency cannot be negative.
-- A rate above 1 means the numerator counts cards that the denominator does not.
select 'mart_card_activation' as model, 'activation_rate' as metric, activation_rate as value
from {{ ref('mart_card_activation') }}
where activation_rate < 0 or activation_rate > 1

union all

select 'mart_card_activation', 'usage_rate', usage_rate
from {{ ref('mart_card_activation') }}
where usage_rate < 0 or usage_rate > 1

union all

select 'mart_card_usage_frequency', 'usage_frequency', usage_frequency
from {{ ref('mart_card_usage_frequency') }}
where usage_frequency < 0
