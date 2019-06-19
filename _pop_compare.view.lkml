# Implementation details here: https://github.com/caitlinkedi/Looker-PoP-Comparison

view: _pop_compare {
  extension: required

  filter: anchor_date_range {
    type: date
    view_label: "PoP Comparison"
    label: "1. Anchor date range"
    description: "Select the date range you want to compare. Make sure any other date filters include this period or are removed."
    }
  parameter: anchor_breakdown_type {
    type: unquoted
    view_label: "PoP Comparison"
    label: "2. Show totals by"
    description: "Choose how you would like to break down the values in the anchor date range."
    allowed_value: {label: "Year" value: "YEAR"}
    allowed_value: {label: "Quarter" value: "QUARTER"}
    allowed_value: {label: "Month" value: "MONTH"}
    allowed_value: {label: "Week" value: "WEEK"}
    allowed_value: {label: "Day" value: "DAY"}
    allowed_value: {label: "Hour" value: "HOUR"}
    default_value: "DAY"}
  parameter: comparison_period_type {
    type: unquoted
    view_label: "PoP Comparison"
    label: "3. Compare to previous"
    description: "Choose the period you want to compare the anchor date range against."
    allowed_value: {label: "Year" value: "YEAR"}
    allowed_value: {label: "Quarter" value: "QUARTER"}
    allowed_value: {label: "Month" value: "MONTH"}
    allowed_value: {label: "Week" value: "WEEK"}
    allowed_value: {label: "Day" value: "DAY"}
    default_value: "MONTH"}
  parameter: num_comparison_periods {
    type: number
    view_label: "PoP Comparison"
    label: "4. Number of past periods"
    description: "Choose how many past periods you want to compare the anchor range against."
    default_value: "1"}

  # Create some helpful values related to the anchor breakdown type (abt)
  # and comparison period type (cpt) fields for later use (see below)
  dimension: abt_format {
    type: string
    hidden: yes
    sql:
      {% if anchor_date_range._is_filtered %}
        {% if anchor_breakdown_type._parameter_value == 'YEAR' %} "'%Y'" --YYYY, e.g. 2019
        {% elsif anchor_breakdown_type._parameter_value == 'MONTH' OR anchor_breakdown_type._parameter_value == 'QUARTER' %} "'%b %Y'" --MON YYYY, e.g. JUN 2019
        {% elsif anchor_breakdown_type._parameter_value == 'HOUR' %} "'%m/%d %r'" --MM/DD 12hrAM/PM, e.g. 06/12 1:00 PM
        {% else %} "'%D'" --MM/DD/YY, e.g. 06/12/19
        {% endif %}
      {% else %} NULL
      {% endif %}
      ;;}
  dimension: cpt_name {
    type: string
    hidden: yes
    sql:
      {% if anchor_date_range._is_filtered %}
        {% if comparison_period_type._parameter_value == 'YEAR' %} 'Year'
        {% elsif comparison_period_type._parameter_value == 'QUARTER' %} 'Quarter'
        {% elsif comparison_period_type._parameter_value == 'MONTH' %} 'Month'
        {% elsif comparison_period_type._parameter_value == 'WEEK' %} 'Week'
        {% else %} 'Day'
        {% endif %}
      {% else %} NULL
      {% endif %}
      ;;}

  # Define and then nicely format values included in the anchor range breakdown segments
  # for use on a chart axis. This relies on the join to _pop_compare_periods in the Explore.
  # Starting with the filter end date, this produces all the date segments needed in the
  # anchor range, then truncates them off to the desired granularity, then formats them
  # based on the definitions in the abt_format dimension above.
  dimension: anchor_dates_unformatted {
    hidden: yes
    type: date_raw
    sql:
      {% if anchor_date_range._is_filtered %}
      DATETIME_TRUNC(DATETIME_ADD(DATETIME({% date_end anchor_date_range %})
                                  ,INTERVAL -1*${_pop_compare_periods.anchor_segment} {% parameter anchor_breakdown_type %}
                                  )
                      ,{% parameter anchor_breakdown_type %})
      {% else %} NULL
      {% endif %}
      ;;}
  dimension: anchor_dates {
    type: string
    view_label: "PoP Comparison"
    order_by_field: anchor_dates_unformatted
    sql:
      {% if anchor_date_range._is_filtered %}
      FORMAT_DATETIME(${_pop_compare_periods.abt_format},${anchor_dates_unformatted})
      {% else %} NULL
      {% endif %}
      ;;}

  # Give nice names to the comparison periods so they can be shown cleanly on charts.
  # This relies on the join to _pop_compare_periods in the Explore.
  dimension: comparison_period_pivot  {
    type: string
    view_label: "PoP Comparison"
    description: "Pivot me! These are the periods being compared."
    order_by_field: period_num
    sql:
      {% if anchor_date_range._is_filtered %}
      CASE ${_pop_compare_periods.period_num}
        WHEN 0 THEN CONCAT('Anchor ', ${cpt_name})
        WHEN 1 THEN CONCAT('1 ',${cpt_name}, ' prior')
        ELSE CONCAT(CAST(${_pop_compare_periods.period_num} as STRING),' ',${cpt_name}, 's prior')
      END
      {% else %} NULL
      {% endif %}
      ;;}

}#End View
