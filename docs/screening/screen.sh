#!/usr/bin/env bash
# Screening only. NOT experiment results (see docs/candidates.md).
set -u

for t in syft grype jq java javac git; do
  command -v "$t" >/dev/null || { echo "missing: $t"; exit 1; }
done

OUT=~/screening
[ -d "$OUT" ] && mv "$OUT" "$OUT.old.$(date +%s)"
mkdir -p "$OUT"
cd ~/app-candidates || exit 1

{
  echo "syft:  $(syft --version 2>&1)"
  echo "grype: $(grype --version 2>&1)"
  echo "java:  $(java -version 2>&1 | head -1)"
  echo "javac: $(javac -version 2>&1)"
  echo "grype db:"; grype db status 2>&1
  echo "date:  $(date -u +%FT%TZ)"
} > "$OUT/env.txt"

declare -A C=( [A]=500158f [B]=8f08b38 [C]=58fe629 [D]=c36452a )

for id in A B C D; do
  c=${C[$id]}
  L="$OUT/$id.log"
  echo "=== $id $c ===" | tee "$L"

  if ! { git clean -fdx -q && git checkout -q "$c"; }; then
    echo "CHECKOUT FAILED" | tee -a "$L"; continue
  fi

  { echo "files:"; ls
    echo "build systems: pom.xml=$([ -f pom.xml ] && echo yes || echo no) build.gradle=$([ -f build.gradle ] && echo yes || echo no)"
    echo "boot parent:"; grep -m1 -A1 "spring-boot-starter-parent" pom.xml
    echo "java props:"; grep -n "java.version\|<release>" pom.xml
  } >> "$L" 2>&1

  # source point: BEFORE any build
  if syft dir:. -o cyclonedx-json="$OUT/sbom-source-$id.json" >> "$L" 2>&1; then
    grype sbom:"$OUT/sbom-source-$id.json" -o json > "$OUT/grype-source-$id.json" 2>>"$L" \
      || echo "GRYPE SOURCE FAILED" >> "$L"
  else
    echo "SYFT SOURCE FAILED" >> "$L"
  fi

  # build point
  if [ -x ./mvnw ] && [ -f pom.xml ]; then
    if ./mvnw -q -DskipTests package >> "$L" 2>&1; then
      jar=$(ls target/*.jar 2>/dev/null | grep -v '\.original$' | head -1)
      if [ -n "$jar" ]; then
        echo "built: $jar" >> "$L"
        if syft "$jar" -o cyclonedx-json="$OUT/sbom-build-$id.json" >> "$L" 2>&1; then
          grype sbom:"$OUT/sbom-build-$id.json" -o json > "$OUT/grype-build-$id.json" 2>>"$L" \
            || echo "GRYPE BUILD FAILED" >> "$L"
        else
          echo "SYFT BUILD FAILED" >> "$L"
        fi
      else
        echo "BUILD OK BUT NO JAR FOUND" >> "$L"
      fi
    else
      echo "BUILD FAILED" >> "$L"
    fi
  else
    echo "NO MVNW/POM: Maven build not attempted" >> "$L"
  fi
done

git clean -fdx -q

# summary
{
  for id in A B C D; do
    for p in source build; do
      f="$OUT/sbom-$p-$id.json"; g="$OUT/grype-$p-$id.json"
      if [ -s "$f" ]; then
        echo "$id $p components=$(jq '.components|length' "$f" 2>&1) cves=$(jq '[.matches[].vulnerability.id]|unique|length' "$g" 2>&1)"
      else
        echo "$id $p NO SBOM"
      fi
    done
  done
  echo "--- problems ---"
  grep -H "FAILED\|NO MVNW\|NO JAR\|missing" "$OUT"/[A-D].log
} | tee "$OUT/summary.txt"
