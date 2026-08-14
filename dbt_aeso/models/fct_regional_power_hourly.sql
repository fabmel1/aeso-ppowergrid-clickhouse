{{ config(
    materialized='incremental',
    engine='MergeTree()',
    order_by=['region_id', 'window_start'],
    unique_key=['region_id', 'window_start']
) }}

SELECT
    toStartOfHour(recorded_at) AS window_start,
    region_id,
    avg(megawatts) AS avg_megawatts,
    max(megawatts) AS max_megawatts,
    avg(pool_price_cad) AS avg_price_cad,
    count() AS total_samples
FROM {{ source('alberta_energy', 'raw_kafka_telemetry') }}

{% if is_incremental() %}
  WHERE recorded_at >= (SELECT max(window_start) FROM {{ this }})
{% endif %}

GROUP BY window_start, region_id