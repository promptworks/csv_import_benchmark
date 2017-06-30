# Importing CSV with Active Record

Finding the absolute fastest way to import a bunch of data from CSV files.

```
                     user     system      total        real
1_dumb:         91.360000   5.860000  97.220000 (136.362367)
2_transaction:  63.140000   2.060000  65.200000 ( 77.661327)
3_csv_foreach:  65.880000   2.100000  67.980000 ( 80.786983)
4_parallel:     1.490000   0.090000 127.900000 ( 42.867716)
```

### Attempt 1: Dumb

This is dumb as hell. Just `CSV.read` the file, then loop over the rows and insert each record.

### Attempt 2: Transaction

Wrap the each call in a transaction. Boom. Faster.

### Attempt 3: Use CSV.foreach

### Attempt 4: Parallel
