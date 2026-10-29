#!/usr/bin/env python3
"""
Levyra Universal Platform Configuration Script
Prepares Android, iOS, and macOS platform manifests and configurations
after `flutter create` runs during CI/CD builds.
"""

import os
import re

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def verify_pubspec():
    pubspec_path = os.path.join(BASE_DIR, "pubspec.yaml")
    if os.path.exists(pubspec_path):
        with open(pubspec_path, "r", encoding="utf-8") as f:
            content = f.read()
        # Ensure package name matches all imports
        if not re.search(r'^name:\s*levyra_music\b', content, re.MULTILINE):
            print("[Pubspec] Ensuring package name is 'levyra_music'...")
            content = re.sub(r'^name:\s*.*$', 'name: levyra_music', content, flags=re.MULTILINE)
            with open(pubspec_path, "w", encoding="utf-8") as f:
                f.write(content)


def cleanup_test_files():
    widget_test = os.path.join(BASE_DIR, "test", "widget_test.dart")
    if os.path.exists(widget_test):
        with open(widget_test, "r", encoding="utf-8") as f:
            content = f.read()
        if "MyApp" in content or "counter" in content or "levyra_universal/main.dart" in content:
            print("[Test Fix] Replacing broken auto-generated widget_test.dart with clean smoke test.")
            with open(widget_test, "w", encoding="utf-8") as f:
                f.write("""import 'package:flutter_test/flutter_test.dart';
import 'package:levyra_music/core/models/unified_track.dart';
import 'package:levyra_music/core/models/unified_artist.dart';

void main() {
  test('Levyra Music Smoke Test', () {
    const artist = UnifiedArtist(id: 'art_1', name: 'Levyra Audiophile');
    const track = UnifiedTrack(
      id: 'ytm:test_smoke_123',
      source: 'youtube_music',
      sourceId: 'test_smoke_123',
      title: 'Smoke Test Track',
      artists: [artist],
      durationMs: 240000,
      thumbnailUrl: 'https://example.com/thumb.jpg',
    );

    expect(track.id, equals('ytm:test_smoke_123'));
    expect(track.artists.first.name, equals('Levyra Audiophile'));
    expect(track.isExplicit, isFalse);
    expect(track.durationMs, equals(240000));
  });
}
""")


def configure_android():
    manifest_path = os.path.join(BASE_DIR, "android", "app", "src", "main", "AndroidManifest.xml")
    if not os.path.exists(manifest_path):
        print(f"[Android] {manifest_path} not found, skipping Android config.")
        return

    print(f"[Android] Configuring {manifest_path}...")
    with open(manifest_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Required Android permissions
    permissions = [
        "android.permission.INTERNET",
        "android.permission.ACCESS_NETWORK_STATE",
        "android.permission.RECORD_AUDIO",
        "android.permission.WAKE_LOCK",
        "android.permission.FOREGROUND_SERVICE",
        "android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK",
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.READ_MEDIA_AUDIO",
        "android.permission.READ_EXTERNAL_STORAGE",
        "android.permission.WRITE_EXTERNAL_STORAGE",
    ]

    perm_elements = []
    for perm in permissions:
        if perm not in content:
            perm_elements.append(f'    <uses-permission android:name="{perm}"/>')

    if perm_elements:
        perms_str = "\n".join(perm_elements) + "\n"
        # Insert before <application
        app_idx = content.find("<application")
        if app_idx != -1:
            content = content[:app_idx] + perms_str + content[app_idx:]
            print(f"[Android] Injected {len(perm_elements)} permissions.")

    # Configure <application
    # 1. usesCleartextTraffic="true" (Essential for local 127.0.0.1 audio cache proxy)
    if 'android:usesCleartextTraffic' not in content:
        content = re.sub(
            r'<application\b',
            '<application\n        android:usesCleartextTraffic="true"',
            content,
            count=1
        )
        print("[Android] Added android:usesCleartextTraffic='true'")

    # 2. Update label to "Levyra Music"
    content = re.sub(r'android:label="[^"]*"', 'android:label="Levyra Music"', content, count=1)

    with open(manifest_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("[Android] Manifest configuration complete.")

    # Configure build.gradle (minSdkVersion at least 21)
    build_gradle = os.path.join(BASE_DIR, "android", "app", "build.gradle")
    if os.path.exists(build_gradle):
        with open(build_gradle, "r", encoding="utf-8") as f:
            gradle_content = f.read()

        if "minSdkVersion 16" in gradle_content:
            gradle_content = gradle_content.replace("minSdkVersion 16", "minSdkVersion 21")
            with open(build_gradle, "w", encoding="utf-8") as f:
                f.write(gradle_content)
            print("[Android] Bumped minSdkVersion from 16 to 21.")


def configure_ios():
    plist_path = os.path.join(BASE_DIR, "ios", "Runner", "Info.plist")
    if not os.path.exists(plist_path):
        print(f"[iOS] {plist_path} not found, skipping iOS config.")
        return

    print(f"[iOS] Configuring {plist_path}...")
    with open(plist_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Background audio playback
    if "UIBackgroundModes" not in content:
        bg_block = """
	<key>UIBackgroundModes</key>
	<array>
		<string>audio</string>
		<string>fetch</string>
	</array>"""
        content = content.replace("</dict>", f"{bg_block}\n</dict>", 1)
        print("[iOS] Added UIBackgroundModes for background audio.")

    # 2. App Transport Security for 127.0.0.1 proxy
    if "NSAppTransportSecurity" not in content:
        ats_block = """
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
		<key>NSAllowsLocalNetworking</key>
		<true/>
	</dict>"""
        content = content.replace("</dict>", f"{ats_block}\n</dict>", 1)
        print("[iOS] Added NSAppTransportSecurity for local cache proxy.")

    # 3. Microphone usage description for recognition
    if "NSMicrophoneUsageDescription" not in content:
        mic_block = """
	<key>NSMicrophoneUsageDescription</key>
	<string>Levyra Music uses microphone access to identify music tracks around you.</string>"""
        content = content.replace("</dict>", f"{mic_block}\n</dict>", 1)
        print("[iOS] Added NSMicrophoneUsageDescription for track recognition.")

    # 4. Display name
    if "<key>CFBundleDisplayName</key>" in content:
        content = re.sub(
            r'<key>CFBundleDisplayName</key>\s*<string>[^<]*</string>',
            '<key>CFBundleDisplayName</key>\n\t<string>Levyra Music</string>',
            content
        )
    else:
        name_block = """
	<key>CFBundleDisplayName</key>
	<string>Levyra Music</string>"""
        content = content.replace("</dict>", f"{name_block}\n</dict>", 1)

    with open(plist_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("[iOS] Info.plist configuration complete.")


def configure_macos():
    entitlements_files = [
        os.path.join(BASE_DIR, "macos", "Runner", "DebugProfile.entitlements"),
        os.path.join(BASE_DIR, "macos", "Runner", "Release.entitlements"),
    ]

    for ent_path in entitlements_files:
        if os.path.exists(ent_path):
            with open(ent_path, "r", encoding="utf-8") as f:
                content = f.read()

            modified = False
            if "com.apple.security.network.client" not in content:
                content = content.replace("</dict>", "\t<key>com.apple.security.network.client</key>\n\t<true/>\n</dict>", 1)
                modified = True
            if "com.apple.security.network.server" not in content:
                content = content.replace("</dict>", "\t<key>com.apple.security.network.server</key>\n\t<true/>\n</dict>", 1)
                modified = True
            if "com.apple.security.device.audio-input" not in content:
                content = content.replace("</dict>", "\t<key>com.apple.security.device.audio-input</key>\n\t<true/>\n</dict>", 1)
                modified = True

            if modified:
                with open(ent_path, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"[macOS] Updated entitlements at {ent_path}")


def main():
    print("=== Levyra Universal: Configuring Platform Manifests ===")
    verify_pubspec()
    configure_android()
    configure_ios()
    configure_macos()
    cleanup_test_files()
    print("=== Platform Configuration Done ===")


if __name__ == "__main__":
    main()
