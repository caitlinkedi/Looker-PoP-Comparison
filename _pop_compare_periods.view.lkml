# Implementation details here: https://github.com/caitlinkedi/Looker-PoP-Comparison
# This view generates a list of integers from 0 to the number defined by the user
# via the _pop_compare parameters for both the anchor date range breakdown and the
# number of time periods being compared.  Then it cross joins them so we have a pair
# for each segment in each comparison period that we can use to calculate the needed
# values in _pop_compare.

include: "_pop_compare.view.lkml"
view: _pop_compare_periods {
  extends: [_pop_compare]
  derived_table: {
    sql:
      SELECT
        period_num
        ,anchor_segment
      FROM UNNEST(GENERATE_ARRAY(0,{% parameter num_comparison_periods %})) as period_num
      CROSS JOIN
        UNNEST(GENERATE_ARRAY(0
              ,DATETIME_DIFF(DATETIME({% date_end anchor_date_range %})
                            ,DATETIME({% date_start anchor_date_range %})
                            ,{% parameter anchor_breakdown_type %}))
              ) as anchor_segment
      ;;
  }

  dimension: period_num {
    hidden: yes
    sql: ${TABLE}.period_num ;;
    type: number}
  dimension: anchor_segment {
    hidden: yes
    sql: ${TABLE}.anchor_segment ;;
    type: number}
}
