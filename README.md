# Looker PoP Comparison

## What is PoP?
PoP means "period over period". A common request from report consumers is to be able to compare the performance of a product or service over a given time period to its performance over a similar period in the past.  This utility allows users to easily compare measures across a flexible set of time periods by choosing an anchor date range and granularity, then the number of past periods to compare.  The code then generates a set of analogous time periods and aligns them with the anchor period for comparison.

## How to implement this thing
This is based on a BigQuery data connection, so you will need to adjust the date functions for other database connections.  Always be cautious with date/time conversions!  If the gotcha below affects your setup, this code block will result in a breathtaking mass of functions wrapping your date fields with potentially unexpected results.  I'll be investigating whether I can make any improvements here in lieu of Looker providing more granular control over how dates/times are handled.

### Common Gotcha
If you have your Looker instance set up to use a Query Time Zone that's different from your Database Time Zone, it will automatically apply a time zone conversion to any date/time field included in the SQL it generates.  To find your database settings: Admin --> Connections (under Database) --> Edit --> Scroll down to the bottom.

Here's an example of the resulting SQL in a setup with the Query Time Zone set to US Central (America - Chicago) and the Database Time Zone in UTC:

`TIMESTAMP(FORMAT_TIMESTAMP('%F %T', transactions.transaction_date , 'America/Chicago'))`

This can be especially challenging as you cannot use `convert_tz: no` with [dates in filters](https://docs.looker.com/reference/field-params/convert_tz). Because I had an unusual mix of timestamp and date fields, the dates coming out of the PoP code block were unexpectedly at 5AM instead of midnight or 7PM (as would be expected for a conversion from UTC to Central time).  My initial attempts at conversion directly in the join or with different combos of date functions were resulting in 7PM on the previous date.  I was able to solve this problem using a hidden `date_raw` type dimension in the view I was querying to do some conversion prior to using my transaction date field with the PoP code block: 

`TIMESTAMP(FORMAT_TIMESTAMP('%F %T',TIMESTAMP(${TABLE}.transaction_date)),'America/Chicago')`.  

That way, when Looker Automatically applied formatting a second time, it was ending up at midnight as desired.

### How to implement in your Looker model
1. Add a copy of the `_pop_compare.view.lkml` view to your project
2. Follow the example in the sample model file to add the `sql_always_where` parameter and a join to `_pop_compare` view to the Explore you'd like to filter. Do not copy and paste the entire Model/Explore; copy only the portions needed.
3. Replace the example field in the join with the date field you'd like to use for filtering. Remember to be cautious with dates as detailed above!

### How to use in a Look
1. Add all four filters from the PoP Comparison field list to your Look. See sample parameter values below.
2. Add the two dimensions from the PoP Comparison field list to your Look (Anchor Dates and Comparison Period Pivot).  Pivot on Comparison Period Pivot.  
3. Add dimensions and measures to your Look as desired. Note that you cannot include additional dimensions beyond the PoP dimensions if you want to make a chart visualization.  You can add as many as you'd like if you want a plain data table output or (I think) certain other visualizations.
4. Run your Look!

#### Filters and Dimensions
![Filters and Dimensions](https://github.com/caitlinkedi/Looker-PoP-Comparison/blob/master/Screenshots/Dimension%20Screenshot.jpg "Filters and Dimensions")

#### Example Look
![Example Look](https://github.com/caitlinkedi/Looker-PoP-Comparison/blob/master/Screenshots/Look%20Screenshot.jpg "Example Look")

## Credits
Inspired by [Date Comparison Block](https://discourse.looker.com/t/date-comparison-block/12198) by bencannon for Datatonic and [Flexible Period-over-Period Block](https://discourse.looker.com/t/analytic-block-flexible-period-over-period-analysis/4507) by fabio for LookerIO. Special thanks to my dog and cats for comforting me when I thought date functions might cause my head to explode.

Discussion thread for this block posted in the Looker Community [here](https://discourse.looker.com/t/period-over-period-date-comparisons/12802). 
