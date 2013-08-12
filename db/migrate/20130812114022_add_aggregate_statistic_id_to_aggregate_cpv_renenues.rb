class AddAggregateStatisticIdToAggregateCpvRenenues < ActiveRecord::Migration
  def change
    add_column :aggregate_cpv_revenues, :aggregate_statistic_id, :integer
    add_column :procurer_cpv_revenues, :aggregate_statistic_id, :integer
  end
end
