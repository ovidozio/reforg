First, use `sqlite3 sources.db < setup_schema.sql` in the database directory to create the database according to the schema.

The user inputs the data for their reference into the `entry.toml` file.
The `so-add` script reads the file and inserts into the database.
This script can be added to the system path and mapped to a keybinding.

Once the database is up, the user can use SQL to write queries
```{bash}
sqlite3 sources.db "SELECT uri FROM sources WHERE title LIKE '%information geometry%';"
```
