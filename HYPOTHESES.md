# Hypotheses

Written before any experiment run. Status of every hypothesis: **UNTESTED**. Tool versions will be pinned in `versions.env` before the first run.

## Definitions
- **"Match"**: the sets of purls are equal after normalization (rules in METHODOLOGY.md).
- **"Point"**: source (no build), build (after mvn package), image (after docker build).
## H1. Source SBOM is incomplete
A SBOM generated from source without Maven dependency resolution misses transitive dependencies present in the build and image SBOMs.
Refute it, if purl sets match for the same tool version on the pinned app.

## H2. VEX built on an incomplete SBOM silences a real CVE
A VEX statement "component_not_present", written against the source SBOM, makes Grype suppress a CVE whose component is present in the image.
Refute it, if Grype ignores the statement, or matches it in a way that does not suppress the finding

## H3. Differences come from the point, not the tool
The differences from H1 remain when the tool is changed (layer B).
Refute it, if differences disappear with another generator at the same point.

## H4. Green control
On a project without transitive dependencies, all three points match.
Refuted it, if points differ even here (then the method itself is suspect).

## Not claimed
Anything about other ecosystems, other scanners, or other VEX formats.

## Disclosure
- All CVEs used in this lab are already public (NVD / GitHub Advisory Database).
- Payloads are harmless markers; no working exploit code is published.
- A new vulnerability found in Petclinic or in a tool used here is reported
  privately to its maintainers first (e.g. https://spring.io/security-policy
  for Spring projects) and is NOT published in this repo until fixed.

## Amendment 2026-10-28 (after screening, before experiment runs)
Screening showed: source SBOM from `dir:.` contains non-application entries
(GitHub Actions, gradle-wrapper) and components with version UNKNOWN.
Consequences for H1:
- Comparison is done on normalized keys (group:artifact), versions separately.
- H1 is split: H1a (component set differs) and H1b (source SBOM lacks versions,
  so the scanner cannot match). Both must be tested separately.

## Amendment 2026-10-30 (before any VEX run)
Added after the experiment design was refined. No VEX has been written or
scanned yet.

## H5. Grype applies a VEX document regardless of its signature
Grype's result with `--vex` is the same for a signed and an unsigned VEX
document, all else equal.
Refuted if: the findings differ between the signed and the unsigned run.
(Whether Grype checks signatures on VEX documents at all: not yet read in
the documentation.)