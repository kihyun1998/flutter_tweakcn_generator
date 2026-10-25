# weight-names

## The fact
A font weight and the word in a file name stand for each other in two tables:
- `FontDownloader.weightNames`: 100 → `Thin`, 200 → `ExtraLight`, … 900 → `Black`.
  It names the files the downloader writes.
- `CustomFontScanner._weightSuffixes`: `Thin` → 100 … `Black` → 900, plus the
  aliases `UltraLight`, `DemiBold`, `UltraBold` and `Heavy`. It reads a weight
  back from a file name.

Every entry in the first must map back to its own number in the second. Checked
at `74a19dd`: all nine round-trip.

## Why it is cross-cutting
The two tables are independent constants in two classes that never call each
other. They meet only through files on disk. A file the downloader wrote in
local mode is read back by the scanner when the project switches to custom mode,
or when the user keeps the downloaded files.

## Territories it holds in
- [font-download](font-download.md): `FontDownloader.weightNames`, used in `downloadEntries`
- [custom-font-scan](custom-font-scan.md): `CustomFontScanner._weightSuffixes`, used in `_weightFor`
- [font-file-naming](font-file-naming.md): `fileNameFor` and `weightSuffixOf` carry the word between the two

## What a violation looks like
A name the downloader writes and the scanner does not know is declared at 400.
Every weight of the family then collapses onto Regular in `pubspec.yaml`. Nothing
fails; bold text simply renders at regular weight. The downloader's fallback
`W<number>`, for a weight outside the table, already lands there today.

## Discovery history
Found by reading during the map's rewrite (2026-10-25). No incident recorded.

## Where it will recur
Any code that writes a weight into a file name, or reads one back out of a name.
