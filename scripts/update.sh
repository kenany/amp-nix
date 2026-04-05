#!/usr/bin/env nu

const STORAGE = "https://static.ampcode.com"
const PLATFORMS = ["darwin-arm64" "darwin-x64" "linux-x64" "linux-arm64"]

def log_info [msg] { print $"(ansi green)[INFO](ansi reset) ($msg)" }
def log_error [msg] { print $"(ansi red)[ERROR](ansi reset) ($msg)" }

def get_current_version [] {
  try {
    open --raw package.nix
      | parse -r 'version = "([^"]*)"'
      | get capture0
      | first
  } catch { "unknown" }
}

def fetch_latest_version [] {
  try { http get $"($STORAGE)/cli/cli-version.txt" | str trim } catch { null }
}

def fetch_native_hash [version: string, platform: string] {
  try {
    let url = $"($STORAGE)/cli/($version)/amp-($platform)"
    let result = (do { ^nix-prefetch-url $url } | complete)
    $result.stdout | lines | last | str trim
  } catch {
    null
  }
}

def update_package_version [version: string] {
  open --raw package.nix
    | str replace -r 'version = "[^"]*"' $'version = "($version)"'
    | save -f package.nix
}

def update_native_hash [platform: string, hash: string] {
  open --raw package.nix
    | str replace -r $'"($platform)" = "[^"]*"' $'"($platform)" = "($hash)"'
    | save -f package.nix
}

def update_to_version [version: string] {
  log_info $"Updating to version ($version)..."
  cp package.nix package.nix.bak

  update_package_version $version
  log_info "Fetching native binary hashes..."

  for platform in $PLATFORMS {
    log_info $"  Fetching hash for ($platform)..."
    let h = (fetch_native_hash $version $platform)

    if ($h == null) {
      log_error $"Failed to fetch native hash for ($platform)"
      mv package.nix.bak package.nix
      return false
    }

    log_info $"  ($platform): ($h)"
    update_native_hash $platform $h
  }

  rm package.nix.bak
  log_info "Verifying build..."

  let build_result = (do { ^nix build "#amp" } | complete)
  if $build_result.exit_code != 0 {
    log_error "Build verification failed"
    return false
  }

  log_info "✅ Build successful!"
  return true
}

def main [--check] {
  let curr = (get_current_version)
  let latest = (fetch_latest_version)

  if ($latest == null or ($latest | str length) == 0) {
    log_error "Failed to fetch latest version"
    exit 1
  }

  log_info $"Current version: ($curr)"
  log_info $"Latest version: ($latest)"

  if $curr == $latest {
    log_info "Already up to date!"
    return
  }

  if $check {
    log_info "Update available!"
    exit 2
  }

  if (update_to_version $latest) {
    log_info $"Successfully updated Amp from ($curr) to ($latest)"
    print ""
    log_info "Changes made:"
    ^git diff --stat package.nix
  } else {
    exit 1
  }
}
