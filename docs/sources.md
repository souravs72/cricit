# CRICIT source list (T01)

Proposed list for the client to sign. Automated access is only used where the source
publishes a public RSS/Atom feed or a documented API. A source whose terms forbid
bots is **dropped**, not scraped around. Status: **proposed — awaiting client approval**.

Adapter key: `rss` | `sitemap` | `html` | `youtube` | `none`.

| Source | Type | Adapter | Feed / listing URL | robots.txt | Terms note | Decision |
|---|---|---|---|---|---|---|
| ESPNcricinfo | news | rss | https://www.espncricinfo.com/rss/content/story/feeds/0.xml | Allows crawlers of public RSS; `/ci/content/rss/` documents feeds | RSS is offered as a free headline feed | **use** |
| ESPNcricinfo (India) | news | rss | https://www.espncricinfo.com/rss/content/story/feeds/6.xml | Same family as above | Country feed, still RSS | **use** |
| BBC Sport Cricket | news | rss | https://feeds.bbci.co.uk/sport/cricket/rss.xml | BBC RSS is public | BBC Terms allow RSS clients; no full-text republish | **use** (summary + link only) |
| The Times of India — Cricket | news | rss | https://timesofindia.indiatimes.com/rssfeeds/4716741.cms | RSS path is public | TOI terms restrict scraping HTML; RSS is the licensed path | **use** |
| NDTV Sports — Cricket | news | rss | https://feeds.feedburner.com/ndtvsports-cricket | Feedburner RSS | Credit + link only | **use** |
| Cricbuzz | news | none | https://www.cricbuzz.com/cricket-news | Disallows broad scraping of `/` in places | No public RSS; HTML scrape would fight robots | **drop** until they offer a feed |
| Sportskeeda Cricket | news | none | https://www.sportskeeda.com/cricket | Mixed; article HTML not a feed | No stable public RSS | **drop** |
| Fox Sports Cricket | news | none | https://www.foxsports.com.au/cricket | Restrictive for bots | No public cricket RSS we can point at | **drop** |
| BCCI | news | html | https://www.bcci.tv/news | Listing pages are public | Official board site; fetch listing only, no article body store | **use** (html adapter, T11) |
| ICC | news | html | https://www.icc-cricket.com/news | Public news listing | Official; listing + link | **use** (html adapter, T11) |
| IPL | news | html | https://www.iplt20.com/news | Public news listing | Official; listing + link | **use** (html adapter, T11) |
| BCCI (YouTube) | video | youtube | channel `UCiErvZ3iVs0LnWoJBWcuK8Q` · uploads `UUiErvZ3iVs0LnWoJBWcuK8Q` | YouTube Data API ToS | Official uploads only; never re-host | **use** |
| ICC (YouTube) | video | youtube | channel `UCt2JXOLNxszYDuYHnmuLuJw` · uploads `UUt2JXOLNxszYDuYHnmuLuJw` | YouTube Data API ToS | Official | **use** |
| Nxtspot (own) | grassroots | none | editorial / submissions | n/a | First-party | **use** |

## What we store

Headline, 60-word summary, credit, original URL, tags, optional image URL we host, YouTube video id.
Never the full article body. Never a downloaded video file.

## Client sign-off

- [ ] Approved by: _______________
- [ ] Date: _______________
- [ ] Message / email reference: _______________
