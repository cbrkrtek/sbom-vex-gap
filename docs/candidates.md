# Candidate applications (screening)

Screening only. Nothing here is an experiment result.
Purpose: choose one Petclinic commit to pin in versions.env.
Selected candidate: none yet.

Source: spring-projects/spring-petclinic. `git ls-remote --tags` returned one
tag, `1.5.x` (c36452a). Candidates are pinned by commit hash. The commit dates
in `git log` are not in chronological order.

## Selection criterion
Written after the first screening run (component and CVE counts were already
known), before any purl-level comparison.
1. The Maven build succeeds on the pinned JDK.
2. The build SBOM has more than 20 components.
3. At least one CVE in the build SBOM belongs to a transitive dependency.
   (Not yet checked.)
Not a criterion: whether the source/build gap is visible.

## Environment
- Syft 1.55.0, Grype 0.121.0, OpenJDK 21.0.12.1 (javac 21.0.12.1).
- Run date: 2026-10-28.
- env.txt was captured before the first Grype run. `grype db status` printed
  `Status: invalid`, `database does not exist`. The Grype DB date used for the
  screening results is not recorded.
- Script: docs/screening/screen.sh. Raw SBOMs, Grype outputs and full logs are
  not committed.
- Commands used: `syft dir:. -o cyclonedx-json=<file>`,
  `syft <jar> -o cyclonedx-json=<file>`, `grype sbom:<file> -o json`,
  `./mvnw -q -DskipTests package`.
- CVE count = `jq '[.matches[].vulnerability.id]|unique|length'` on the Grype
  JSON. Component count = `jq '.components|length'` on the SBOM.
- Syft printed on every directory scan: "no explicit name and version provided
  for directory source, deriving artifact ID from the given path".

## Overview
Dates are commit dates from `git log`, not release dates.

| ID | Commit | Date | Boot parent | java.version | Source: components / CVEs | Build: components / CVEs | Status |
|----|--------|------|-------------|--------------|---------------------------|--------------------------|--------|
| A | 500158f | 2026-09-29 | 4.1.0 | 17 | 42 / 0 | 94 / 17 | candidate |
| B | 8f08b38 | 2025-10-29 | 4.0.0 | 25 | 37 / 0 | build failed | excluded for now |
| C | 58fe629 | 2022-01-05 | 2.6.2 | 1.8 | 25 / 0 | 85 / 131 | candidate |
| D | c36452a (tag 1.5.x) | not recorded | 1.5.4.RELEASE | 1.8 | 19 / 6 | build failed | excluded |

## Notes per candidate

### A (500158f)
- pom.xml and build.gradle both present.
- Maven build succeeded on JDK 21. Artifact: target/spring-petclinic-4.0.0-SNAPSHOT.jar.

### B (8f08b38)
- pom.xml and build.gradle both present.
- Build failed on JDK 21: maven-enforcer rule `enforce-java`:
  "This build requires at least Java 25". pom.xml has `<java.version>25</java.version>`.

### C (58fe629)
- pom.xml and build.gradle both present.
- Maven build succeeded on JDK 21. Artifact: target/spring-petclinic-2.6.0-SNAPSHOT.jar.
- Source SBOM, first entries viewed: `pkg:github/actions/checkout@v2`,
  `pkg:github/actions/setup-java@v2`, `gradle-wrapper` (version UNKNOWN),
  and `cache-api`, `ehcache`, `h2` with version UNKNOWN and purls without version.

### D (c36452a)
- pom.xml only. The wrapper downloaded Maven 3.3.3.
- Build failed in `ro.isdc.wro4j:wro4j-maven-plugin:1.8.0:run`:
  `ExceptionInInitializerError`, message "An API incompatibility was
  encountered". The error text also contains a Mockito PluginRegistry message.
- Excluded.

## Raw purl comparison (invalid)
First attempt with `comm` on unnormalized purls: A common 3, build-only 90,
source-only 32; C common 1, build-only 83, source-only 20. `comm` reported
unsorted input. Do not interpret these numbers.

## Open questions
1. Why do the source SBOMs of A, B, C give 0 CVEs while D's gives 6?
2. Comparison with `LC_ALL=C` and normalized keys (group:artifact), excluding
   pkg:github and gradle entries; versions compared separately.
3. Which build-SBOM CVEs belong to components absent from the source SBOM?
4. Which CVEs belong to transitive dependencies?
5. Pinned JDK for A and C.
6. Grype DB date: record it in a rerun (update DB, status, then scan).

## Decision
Selected: A, commit 500158f732419217507c7656904b8e6aa1bcc0d6 (hash from git log).
Chosen by the author's decision: most recent code, 17 CVEs on the build SBOM
in screening. Criterion item 3 (CVE in a transitive dependency) and open
questions 2-6 were NOT answered before the choice; they are answered during
the experiments.