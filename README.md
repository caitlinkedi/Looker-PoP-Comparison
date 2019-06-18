# Looker PoP Comparison

## What is PoP?
PoP means period over period. A common request from report consumers is to compare the performance of a product or service over a time period as compared to performance in the past.  This utility allows you to easily compare measures across a flexible set of time periods by using an anchor date range, then generating a set of analogous time periods based on the user's choice of granularity and number of past periods to compare.

## How to implement this thing
This is based on a BigQuery data connection, so you will need to adjust the date functions for other database connections.  Always be cautious with date/time conversions!  If the gotcha below affects your setup, this code block will result in a breathtaking mass of functions wrapping your date fields with potentially unexpected results.  I'll be investigating whether I can make any improvements here in lieu of Looker providing more granular control over how dates/times are handled.

### Common Gotcha
If you have your Looker instance set up to use a Query Time Zone that's different from your Database Time Zone, it will automatically apply a time zone conversion to any date/time field included in the SQL it generates.  An example of the resulting SQL in a setup with the Query Time Zone set to US Central (America - Chicago) and the Database Time Zone in UTC is shown below.  It can be especially challenging as you cannot use `convert_tz: no` with [dates in filters](https://docs.looker.com/reference/field-params/convert_tz).  As a result, I needed to create a hidden `date_raw` dimension in the view I was querying to do some heavy conversion prior to using it with the PoP code block (see example below).  The dates coming out of the PoP code block were unexpectedly at 5AM on the date in question, but my initial attempts at conversion using fewer functions were resulting in 7PM on the previous date as would be expected for a conversion from UTC to Central time.  The conversion shown below turns 2019-06-18 00:00 into 2019-06-18 05:00. 

* To find these settings: Admin --> Connections (under Database) --> Edit --> Scroll down to the bottom
* Looker's automatic date conversion: `TIMESTAMP(FORMAT_TIMESTAMP('%F %T', transactions.transaction_date , 'America/Chicago'))`
* Hidden dimension workaround: `TIMESTAMP(FORMAT_TIMESTAMP('%F %T',TIMESTAMP(${TABLE}.transaction_date)),'America/Chicago')`

### How to implement in your Looker model
1. Add a copy of the `_pop_compare.view.lkml` and `_pop_compare_periods.view.lkml` views into your project
2. In the Explore you want to be able to filter, add the `sql_always_where` clause shown in the model file here. Replace the example fields with those you'd like to use. Remember to be cautious with dates!

### How to use in a Look
1. Add all four filters from the PoP comparison field list to your Look. See sample parameter values below.
2. Add the two dimensions from the PoP comparison field list to your Look.  Pivot on `prior_period_pivot`.  
3. Add dimensions and measures to your Look as desired. Note that you cannot include additional dimensions beyond the PoP dimensions if you want to make a chart visualization.  You can add as many as you'd like if you want a plain data table output.
4. Run your Look!
