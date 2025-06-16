# run the web server
[group("server")]
run:
    dune exec dream-template -w

# run tailwindcss
[group("server")]
css:
    tailwindcss -i lib/client/tailwindcss/input.css -o lib/client/static/main.css -m --watch

test:
    dune test

format:
    dune @fmf
# start the database
[group("database")]
pg-start:
    pg_ctl -D $PG_DATA -o "-k $PG_HOST" -l "$PG_DATA/logs" start

# stop the database
[group("database")]
pg-stop:
    pg_ctl -D $PG_DATA stop

# interactive mode to query the database
[group("database")]
pg-repl:
    psql --host $PG_HOST -U postgres

# migrate up to the next schema
[group("database")]
up:
    dbmate up

# migrate down to the previous schema
[group("database")]
down:
    dbmate down
