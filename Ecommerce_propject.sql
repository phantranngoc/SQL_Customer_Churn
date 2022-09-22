-- Big project for SQL

-- Query 01: calculate total visit, pageview, transaction and revenue from Jan to Mar 2017
#standardSQL
select 
  date,   
  sum (totals.visits) as visits,
  sum (totals.pageviews) as pageviews,
  sum (totals.transactions) as transactions,
  sum (totals.transactionRevenue)/1000000 as revenue
from `bigquery-public-data.google_analytics_sample.ga_sessions_*` 
where _table_suffix between '20170101' and '20170331'


-- Query 02: Bounce rate per traffic source in July 2017
#standardSQL
select 
      source, 
      total_visits, 
      total_no_of_bounces, 
      ((total_no_of_bounces/total_visits)*100) as bounce_rate
from(  
      select 
            trafficSource.source as source, 
            count(trafficSource.source) as total_visits, 
            sum(totals.bounces) as total_no_of_bounces
      from `bigquery-public-data.google_analytics_sample.ga_sessions_201707*` 
      group by source)
order by total_visits desc;


-- Query 3: Revenue by traffic source by week, by month in June 2017
/*
With month_data as(
SELECT
  "Month" as time_type,
  format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
  trafficSource.source AS source,
  SUM(totals.totalTransactionRevenue)/1000000 AS revenue
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE
_TABLE_SUFFIX BETWEEN '20170601' AND '20170631'
GROUP BY 1,2,3
order by revenue DESC
),

week_data as(
SELECT
  "Week" as time_type,
  format_date("%Y%W", parse_date("%Y%m%d", date)) as date,
  trafficSource.source AS source,
  SUM(totals.totalTransactionRevenue)/1000000 AS revenue
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE
_TABLE_SUFFIX BETWEEN '20170601' AND '20170631'
GROUP BY 1,2,3
order by revenue DESC
)

select * from month_data
union all
select * from week_data
*/

--Query 04: Average number of product pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017. Note: totals.transactions >=1 for purchaser and totals.transactions is null for non-purchaser
#standardSQL
select 
  case when totals.transactions >= 1 then 'avg_pageviews_purchase'
       when totals.transactions is null then 'avg_pageviews_non_purchase'
        else 'N/A' end as outcome 
from (
      select 
          (sum (total_pageviews)/ count(number_unique_user)) as avg_pageviews_purchase, 
          (sum (total_pageviews)/ count(number_unique_user)) as avg_pageviews_non_purchase 
      from (
            select
                  distinct(fullVisitorId) as number_unique_user, 
                  sum(totals.pageviews) as total_pageviews
            from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
            where date between '20170601' and '20170731'
            group by number_unique_user) 

-- Query 05: Average number of transactions per user that made a purchase in July 2017
#standardSQL

select
    format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
    sum(totals.transactions)/count(distinct fullvisitorid) as Avg_total_transactions_per_user
from `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
where  totals.transactions>=1
group by month;

-- Query 06: Average amount of money spent per session
#standardSQL
select
    format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
    ((sum(totals.totalTransactionRevenue)/sum(totals.visits))/power(10,6)) as avg_revenue_by_user_per_visit
    
from `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    
where  totals.transactions is not null
group by month;








