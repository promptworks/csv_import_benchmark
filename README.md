# Importing CSV with Active Record

#### TL;DR

Don't do this.

```ruby
rows = CSV.read(DATA_FILE, headers: true)
rows.each { |row| Model.create!(row.to_h) }
```

Take a look at [benchmark.rb](benchmark.rb) for implementations.

#### Importing 100,000 rows:

| description                                              | user      | system    |  total     | real         |
|----------------------------------------------------------|-----------|-----------|------------|--------------|
| 1. `CSV.read`                                            | 94.390000 | 6.610000  | 101.000000 | (148.314696) |
| 2. `CSV.foreach`                                         | 99.010000 | 6.690000  | 105.700000 | (156.682188) |
| 3. `Model.transaction`                                   | 72.070000 | 2.960000  |  75.030000 | ( 93.792229) |
| 4. `Model.import`                                        | 14.240000 | 0.170000  |  14.410000 | ( 16.573315) |
| 5. `Model.bulk_insert`                                   |  5.550000 | 0.110000  |   5.660000 | (  6.944650) |
| 6. `PG::Connection#copy_data`                            |  1.010000 | 0.060000  |   1.070000 | (  1.130262) |
| 7. `PG::Connection#copy_data` (CSV)                      |  0.150000 | 0.030000  |   0.180000 | (  0.421892) |

#### Importing 1,000,000 rows:

| Description                                             | user        | system    |   total    |     real      |
|---------------------------------------------------------|-------------|-----------|------------|---------------|
| 1. `CSV.read` *skipped*                                 |             |           |            |               |
| 2. `CSV.foreach`                                        | 754.090000  | 49.220000 | 803.310000 | (1098.404694) |
| 3. `Model.transaction`                                  | 585.320000  | 21.780000 | 607.100000 | (742.589200)  |
| 4. `Model.import`                                       | 131.560000  |  0.530000 | 132.090000 | (147.269124)  |
| 5. `Model.bulk_insert`                                  | 54.290000   |  0.550000 | 54.840000  | ( 63.172003)  |
| 6. `PG::Connection#copy_data`                           | 10.090000   |  0.400000 | 10.490000  | ( 10.894156)  |
| 7. `PG::Connection#copy_data` (CSV)                     |  1.220000   |  0.300000 |  1.520000  | (  3.989271)  |
