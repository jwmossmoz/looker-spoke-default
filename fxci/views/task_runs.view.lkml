include: "//looker-hub/fxci/views/task_runs_base.view.lkml"

view: task_runs {
  extends: [task_runs_base]

  dimension: key {
    primary_key:  yes
    sql: CONCAT(${TABLE}.task_id, '-', ${TABLE}.run_id) ;;  }

  # Azure physical region names from az account list-locations, 2026-09-16.
  # Add new Azure regions when Taskcluster starts to use them.
  dimension: cloud_provider {
    type: string
    label: "Cloud Provider (Worker Group)"
    description: "Provider from the worker group. Includes runs without cost records. Unknown and unassigned groups are other."
    sql:
      CASE
        WHEN ${worker_group} IN (
          'australiacentral', 'australiacentral2', 'australiaeast', 'australiasoutheast', 'austriaeast',
          'belgiumcentral', 'brazilsouth', 'brazilsoutheast', 'canadacentral', 'canadaeast',
          'centralindia', 'centralus', 'centraluseuap', 'chilecentral', 'denmarkeast',
          'eastasia', 'eastus', 'eastus2', 'eastus2euap', 'eastusstg',
          'francecentral', 'francesouth', 'germanynorth', 'germanywestcentral', 'indiasouthcentral',
          'indonesiacentral', 'israelcentral', 'italynorth', 'japaneast', 'japanwest',
          'jioindiacentral', 'jioindiawest', 'koreacentral', 'koreasouth', 'malaysiawest',
          'mexicocentral', 'newzealandnorth', 'northcentralus', 'northeurope', 'norwayeast',
          'norwaywest', 'polandcentral', 'qatarcentral', 'southafricanorth', 'southafricawest',
          'southcentralus', 'southcentralusstg', 'southeastasia', 'southindia', 'spaincentral',
          'swedencentral', 'switzerlandnorth', 'switzerlandwest', 'uaecentral', 'uaenorth',
          'uksouth', 'ukwest', 'westcentralus', 'westeurope', 'westindia',
          'westus', 'westus2', 'westus3'
        ) THEN 'azure'
        WHEN REGEXP_CONTAINS(${worker_group}, r'^(africa|asia|australia|europe|me|northamerica|southamerica|us)-[a-z]+[0-9]+-[a-z]$') THEN 'gcp'
        ELSE 'other'
      END ;;
  }

  parameter: date_bucket {
    type: string
    label: "Date Bucket"
    allowed_value: { label: "None" value: "none" }
    allowed_value: { label: "Day" value: "day" }
    allowed_value: { label: "Week" value: "week" }
    allowed_value: { label: "Month" value: "month" }
    allowed_value: { label: "Quarter" value: "quarter" }
    default_value: "day"
  }

  dimension: date {
    type: date
    sql:
    CASE
      WHEN {% parameter date_bucket %}  = 'day' THEN ${task_runs.submission_date}
      WHEN {% parameter date_bucket %}  = 'week' THEN DATE(FORMAT_DATE('%F', DATE_TRUNC(${task_runs.submission_date} , WEEK(SUNDAY))))
      WHEN {% parameter date_bucket %}  = 'month' THEN DATE(FORMAT_DATE('%Y-%m-%d', DATE_TRUNC(${task_runs.submission_date}, MONTH )))
      WHEN {% parameter date_bucket %}  = 'quarter' THEN DATE(FORMAT_DATE('%Y-%m-%d', DATE_TRUNC(${task_runs.submission_date} , QUARTER)))
      ELSE DATE "1970-01-01"
    END
  ;;
  }

  dimension: duration {
    type: duration_second
    sql_start: ${started_raw} ;;
    sql_end:  ${resolved_raw} ;;
    label: "Duration"
    description: "Time in seconds from when the task started, to when it was resolved."
  }

  dimension: pending_duration {
    type: duration_second
    sql_start: ${scheduled_raw} ;;
    sql_end:  ${started_raw} ;;
    label: "Pending Duration"
    description: "Time in seconds from when the task was scheduled, to when it started."
  }

  measure: task_run_count {
    type: count
    label: "Run Count"
    description: "Number of task runs."
  }

  measure: average_duration {
    type: average
    sql: ${duration} ;;
    label: "Average Duration"
    description: "Average duration in seconds"
  }
}
