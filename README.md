# Importing CSV with Active Record

Finding the absolute fastest way to import a bunch of data from CSV files.

```
                      user     system      total        real
1_dumb:          91.360000   5.860000  97.220000 (136.362367)
2_transaction:   63.140000   2.060000  65.200000 ( 77.661327)
3_csv_foreach:   65.880000   2.100000  67.980000 ( 80.786983)
4_ar_import:     15.480000   0.140000  15.620000 ( 17.191608)
5_parallel:      1.630000   0.080000  26.730000 (  9.496539)
6_pg_copy:       1.050000   0.070000   2.480000 (  1.763642)
7_pg_copy_csv:   0.100000   0.040000   1.310000 (  0.678814)
```

### Attempt 1: Dumb

This is dumb as hell. Just `CSV.read` the file, then loop over the rows and insert each record.

### Attempt 2: Transaction

Wrap the each call in a transaction. Boom. Faster.

### Attempt 3: Use CSV.foreach

### Attempt 4: ActiveRecord::Import

### Attempt 5: Parallel

### Attempt 6: Postgres Copy

### Attempt 7: Postgres Copy CSV
