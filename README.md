# Importing CSV with Active Record

Finding the absolute fastest way to import a bunch of data from CSV files.

| Attempt        | Time                                         |
|----------------|----------------------------------------------|
| 1. Dumb        | 81.100000   5.110000  86.210000 (117.494417) |
| 2. Transaction | 66.310000   2.720000  69.030000 ( 84.010406) |
| 3. CSV Foreach | 64.400000   2.450000  66.850000 ( 80.798659) |

### Attempt 1: Dumb

This is dumb as hell. Just `CSV.read` the file, then loop over the rows and insert each record.

### Attempt 2: Transaction

Wrap the each call in a transaction. Boom. Faster.

### Attempt 3: Use CSV.foreach
