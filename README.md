# Setlist Maker

A one-set setlist planner for bands: band logo, venue and date, a song list with notes,
a song library, and an A4 print download.

**Live:** https://jehte.github.io/setlist-maker/

Setlists are shared through Supabase. Enter the band password once per device;
without it, the app works and saves setlists in that browser only.

## Editing

Edit `src/setlist.html`, then run `sh build.sh` to regenerate `index.html`.

## Database

`supabase/schema.sql` creates the tables, access rules and live updates.
The band login is the Supabase user `band@setlist-maker.app`; its password is the band password.
