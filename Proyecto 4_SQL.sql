SELECT DISTINCT event_name
FROM mercadolibre_funnel 
ORDER BY event_name ;

WITH first_visits AS (
  SELECT DISTINCT user_id, country
  FROM mercadolibre_funnel
  WHERE event_name = 'first_visit'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
select_item AS (
  SELECT DISTINCT user_id, country
  FROM mercadolibre_funnel
  WHERE event_name IN ('select_item', 'select_promotion')
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
add_to_cart AS (
  SELECT DISTINCT user_id, country
  FROM mercadolibre_funnel
  WHERE event_name = 'add_to_cart'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
begin_checkout AS (
  SELECT DISTINCT user_id, country
  FROM mercadolibre_funnel
  WHERE event_name = 'begin_checkout'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
add_shipping_info AS (
  SELECT DISTINCT user_id, country
  FROM mercadolibre_funnel
  WHERE event_name = 'add_shipping_info'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
add_payment_info AS (
  SELECT DISTINCT user_id, country
  FROM mercadolibre_funnel
  WHERE event_name = 'add_payment_info'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
purchase AS (
  SELECT DISTINCT user_id, country
  FROM mercadolibre_funnel
  WHERE event_name = 'purchase'
    AND event_date BETWEEN '2025-01-01' AND '2025-08-31'
),
funnel_counts AS (
  SELECT
    fv.country,
    COUNT(DISTINCT fv.user_id)  AS usuarios_first_visit,
    COUNT(DISTINCT si.user_id)  AS usuarios_select_item,
    COUNT(DISTINCT a.user_id)   AS usuarios_add_to_cart,
    COUNT(DISTINCT bc.user_id)  AS usuarios_begin_checkout,
    COUNT(DISTINCT asi.user_id) AS usuarios_add_shipping_info,
    COUNT(DISTINCT api.user_id) AS usuarios_add_payment_info,
    COUNT(DISTINCT p.user_id)   AS usuarios_purchase
  FROM first_visits fv
  LEFT JOIN select_item si        ON fv.user_id = si.user_id AND fv.country = si.country
  LEFT JOIN add_to_cart a         ON fv.user_id = a.user_id AND fv.country = a.country
  LEFT JOIN begin_checkout bc     ON fv.user_id = bc.user_id AND fv.country = bc.country
  LEFT JOIN add_shipping_info asi ON fv.user_id = asi.user_id AND fv.country = asi.country
  LEFT JOIN add_payment_info api  ON fv.user_id = api.user_id AND fv.country = api.country
  LEFT JOIN purchase p            ON fv.user_id = p.user_id AND fv.country = p.country
  GROUP BY fv.country
)

SELECT
    country,
    usuarios_select_item * 100.0 / NULLIF(usuarios_first_visit, 0) AS conversion_select_item,
    usuarios_add_to_cart * 100.0 / NULLIF(usuarios_first_visit, 0) AS conversion_add_to_cart,
    usuarios_begin_checkout * 100.0 / NULLIF(usuarios_first_visit, 0) AS conversion_begin_checkout,
    usuarios_add_shipping_info * 100.0 / NULLIF(usuarios_first_visit, 0) AS conversion_add_shipping_info,
    usuarios_add_payment_info * 100.0 / NULLIF(usuarios_first_visit, 0) AS conversion_add_payment_info,
    usuarios_purchase * 100.0 / NULLIF(usuarios_first_visit, 0) AS conversion_purchase
FROM funnel_counts
ORDER BY conversion_purchase DESC;

WITH cohort AS (
    SELECT
        user_id,
        TO_CHAR(
            DATE_TRUNC('month', MIN(signup_date)::date),
            'YYYY-MM'
        ) AS cohort
    FROM mercadolibre_retention
    GROUP BY user_id
),
activity AS (
    SELECT
        r.user_id,
        c.cohort,
        r.day_after_signup,
        r.active
    FROM mercadolibre_retention r
    INNER JOIN cohort c
        ON r.user_id = c.user_id
    WHERE r.activity_date BETWEEN '2025-01-01' AND '2025-08-31'
)

SELECT
    cohort,
    ROUND(
        100.0 * COUNT(DISTINCT CASE 
            WHEN day_after_signup >= 7 AND active = 1 THEN user_id 
        END) / NULLIF(COUNT(DISTINCT user_id), 0),
        1
    ) AS retention_d7_pct,
    ROUND(
        100.0 * COUNT(DISTINCT CASE 
            WHEN day_after_signup >= 14 AND active = 1 THEN user_id 
        END) / NULLIF(COUNT(DISTINCT user_id), 0),
        1
    ) AS retention_d14_pct,
    ROUND(
        100.0 * COUNT(DISTINCT CASE 
            WHEN day_after_signup >= 21 AND active = 1 THEN user_id 
        END) / NULLIF(COUNT(DISTINCT user_id), 0),
        1
    ) AS retention_d21_pct,
    ROUND(
        100.0 * COUNT(DISTINCT CASE 
            WHEN day_after_signup >= 28 AND active = 1 THEN user_id 
        END) / NULLIF(COUNT(DISTINCT user_id), 0),
        1
    ) AS retention_d28_pct
FROM activity
GROUP BY cohort
ORDER BY cohort;

