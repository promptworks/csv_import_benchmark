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
| 1. `CSV.read`                                            | 83.100000 |  5.440000 |  88.540000 | (123.526042) |
| 2. `CSV.foreach`                                         | 87.520000 |  5.600000 |  93.120000 | (131.989104) |
| 3. `Model.transaction`                                   | 78.620000 |  3.260000 |  81.880000 | (101.395879) |
| 4. `Model.import`                                        | 14.140000 |  0.120000 |  14.260000 | ( 16.151450) |
| 5. `Model.bulk_insert`                                   |  4.810000 |  0.050000 |   4.860000 | (  5.534681) |
| 6. `PG::Connection#copy_data`                            |  0.830000 |  0.040000 |   0.870000 | (  0.890782) |
| 7. `Parallel.each` -> `Model.bulk_insert`                |  0.790000 |  0.040000 |  10.570000 | (  4.361407) |
| 8. `Parallel.each` -> `PG::Connection#copy_data`         |  0.840000 |  0.030000 |   2.700000 | (  1.514069) |
| 9. `Parallel.each` -> `PG::Connection#copy_data` (CSV)   |  0.090000 |  0.020000 |   1.430000 | (  0.651984) |

#### Importing 1,000,000 rows:

| Description                                             | user        | system    |   total    |     real      |
|---------------------------------------------------------|-------------|-----------|------------|---------------|
| 1. `CSV.read` *skipped*                                 |             |           |            |               |
| 2. `CSV.foreach`                                        | 754.090000  | 49.220000 | 803.310000 | (1098.404694) |
| 3. `Model.transaction`                                  | 585.320000  | 21.780000 | 607.100000 | (742.589200)  |
| 4. `Model.import`                                       | 131.560000  |  0.530000 | 132.090000 | (147.269124)  |
| 5. `Model.bulk_insert`                                  |  48.450000  |  0.300000 |  48.750000 | ( 55.785728)  |
| 6. `PG::Connection#copy_data`                           |   8.990000  |  0.370000 |   9.360000 | (  9.487991)  |
| 7. `Parallel.each` -> `Model.bulk_insert`               |   9.550000  |  0.420000 |  93.380000 | ( 36.972469)  |
| 8. `Parallel.each` -> `PG::Connection#copy_data`        |   9.410000  |  0.270000 |  20.320000 | ( 14.573306)  |
| 9. `Parallel.each` -> `PG::Connection#copy_data` (CSV)  |   1.200000  |  0.170000 |   5.000000 | (  4.094947)  |
