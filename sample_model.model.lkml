# Example model file

connection: "bigquery"
include: "*.view.lkml"
include: "*.explore.lkml"

explore: sample_explore {
  from: sample_table
  view_label: "Here's a Nice Display Name"
  description: "This is an example explore that uses the PoP Comparison utility"

  # Add the clause shown after the AND to your explore
  sql_always_where:
    ${sample_table.sample_field_to_filter} IN ('Foo','Bar')
    AND ({% if _pop_compare_periods.anchor_date_range._is_filtered %}
          ${_pop_compare_periods.period_num} IS NOT NULL
        {% else %} 1 = 1
        {% endif %})
    ;;

  # Add this join to your explore, and replace the field indicated below with the date you'd like
  # to apply the PoP filter to. This takes all the possible segments within all possible periods by
  # subtracting the segment number from the parameter end date, then subtracting the period number
  # from that.  A value from the data source in question is included if it's on one of those dates.
  join: _pop_compare_periods {
    type: left_outer
    relationship: many_to_one
    sql_on: DATETIME_TRUNC(DATETIME(${transactions.dt_txn_posted_pop}),{% parameter _pop_compare_periods.anchor_breakdown_type %})
            =DATETIME_TRUNC(DATETIME_ADD(DATETIME_ADD(DATETIME({% date_end _pop_compare_periods.anchor_date_range %})
                                                      ,INTERVAL -1*${_pop_compare_periods.anchor_segment} {% parameter _pop_compare_periods.anchor_breakdown_type %})
                                        ,INTERVAL -1*${_pop_compare_periods.period_num} {% parameter _pop_compare_periods.comparison_period_type %})
                            ,{% parameter _pop_compare_periods.anchor_breakdown_type %})
            ;;
    } # End join _pop_compare_periods

} # End explore my_sample_explore
