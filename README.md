# cpi-calculator

Israeli CPI linkage calculator (מחשבון הצמדה למדד המחירים לצרכן) plus the full
monthly index table from 2014 on. Hebrew, RTL, one file.

You give it an amount and a start date; it tells you what that amount is worth
linked to the index **as known today**, and shows the arithmetic it used.

## Running it

There is no build step and there are no dependencies — `index.html` is a
complete standalone document. Open it in a browser and it works:

```bash
start index.html          # or just double-click it
```

Served as a container (this is how it runs in the stack):

```bash
docker build -t cpi-calculator .
docker run --rm -p 8010:80 cpi-calculator
# http://localhost:8010
```

In the [Orchestra](../Orchestra) stack it is the `cpi-calculator` service on
port **8010**, profile `web`, behind the wildcard Cloudflare Access policy.

**The container bind-mounts this repo read-only as the nginx web root, so a
`git pull` on the host updates the live page with no image rebuild.** That is
deliberate — see the comment on the volume in Orchestra's `docker-compose.yml`.
Rebuilding is only needed if the Dockerfile itself changes.

## The part that needs maintenance: the index data

`DATA` in `index.html` is a hardcoded array of
`[year, month, published_index, normalised_index]`, currently running **2014-01
through 2026-06**. Nothing fetches it; the CBS publishes a new index each month
and somebody has to paste it in.

When the table falls behind, the calculator does not fail — it **clamps to the
last month it has** and flags the result as clamped. So a stale table shows up
as quietly conservative answers rather than an error. That is the failure mode
to know about.

To add a month: append one row to `DATA`, keeping both columns (below), and
commit. The page picks it up on the next load; on the deployed host, after a
`git pull`.

### Why there are two index columns

The CBS **rebases** the index periodically — it resets to 100.0 and the
published number stops being comparable across the boundary. This repo's data
records rebases in January of **2015, 2021, 2023 and 2025** (`REBASE_MONTHS`).

- `published_index` — the number as the CBS printed it that month. This is what
  the table displays, so it matches any official document you hold.
- `normalised_index` — the same series chained across every rebase, so ratios
  are valid over any span.

**The calculation uses the normalised column** (`factor = end.norm / start.norm`).
Using the published numbers across a rebase boundary would give a wrong answer,
which is the whole reason the second column exists. If you add a month that is
itself a rebase, add it to `REBASE_MONTHS` too.

## "The index known today"

Israeli linkage does not use the current month's index, because it has not been
published yet. The index for month *M* is published on the **15th** of month
*M+1* (the 14th when the 15th falls on a Saturday — `pubDay`).

So for a given date, `knownIndexForDate` picks:

- the **previous** month's index, if today is on or after publication day
- the month **before that**, if it is earlier in the month

This is the convention contracts and rent agreements mean by "המדד הידוע". The
date picker is capped at today, so you cannot ask for a future index.

## Layout

```
index.html    The whole application — markup, styles, data and logic
Dockerfile    nginx:1-alpine3.24, repo root copied to the web root
```
