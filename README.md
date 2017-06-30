# Importing CSV with Active Record

Finding the absolute fastest way to import a bunch of data from CSV files.

| Attempt | Time                                          |
|---------|-----------------------------------------------|
| 1. Dumb |  81.100000   5.110000  86.210000 (117.494417) |

### Attempt 1: Dumb

This is dumb as hell. Just `CSV.read` the file, then loop over the rows and insert each record.
