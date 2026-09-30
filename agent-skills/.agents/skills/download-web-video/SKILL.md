---
name: download-web-video
description: Resolve, download, resume, and verify video exposed by a web page. Use when Codex needs to save an authorized web video from a page URL, direct media URL, browser-loaded media element, HLS/DASH manifest, or short-lived signed media request.
---

# Download Web Video

Use the simplest source the page legitimately exposes. Prefer established command-line tools and direct media requests over extensions, download portals, or unreviewed executables.

## Resolve the media

Use this fallback order:

1. Try a maintained media resolver against the page URL:

   ```bash
   yt-dlp --no-update --list-formats "$PAGE_URL"
   ```

   If extraction fails because the installed resolver is stale, check its version and update that existing installation from its trusted package source before retrying.

2. Inspect the page HTML and structured data for ordinary `<video>`, `<source>`, direct media, or manifest URLs.

3. If the media is available only in a browser session the user can already access, inspect the loaded page or DevTools network log. Useful JavaScript probes are:

   ```js
   document.querySelector("video")?.currentSrc
   [...document.querySelectorAll("video source")].map(source => source.src)
   performance.getEntriesByType("resource")
     .map(entry => entry.name)
     .filter(url => /\.(mp4|webm|m3u8|mpd|m4s|ts)(\?|$)/i.test(url))
   ```

   Prefer returning results directly from browser evaluation. Do not place signed URLs, cookies, or request headers on the system clipboard or in persistent temporary files.

4. If a page uses an official signing request to produce a short-lived media URL, use the page's normal request flow. Treat the URL as secret and expect it to expire.

## Select the format

Inspect available formats before downloading. Choose by stable properties—resolution, bitrate, codecs, audio presence, and container—not by a transient format ID when the source may rotate IDs.

Always favor the highest-quality complete stream, with H.264/AAC in MP4 for broad compatibility. Explain before choosing AV1 or HEVC when compatibility may matter.

## Download

For a page or manifest supported by the resolver, use resumable output and let it merge segmented audio/video:

```bash
yt-dlp --no-update --continue --concurrent-fragments 4 \
  --merge-output-format mp4 \
  -o "$OUTPUT_TEMPLATE" "$PAGE_OR_MANIFEST_URL"
```

Add only the referer, user agent, or browser-session data that the successful browser request actually requires. Never print authentication data or signed URLs in status updates.

For a direct media object, inspect its headers and then download resumably:

```bash
curl -sSIL --referer "$PAGE_URL" "$MEDIA_URL"
curl --fail --location --continue-at - \
  --referer "$PAGE_URL" --user-agent "$USER_AGENT" \
  --output "$OUTPUT_FILE" "$MEDIA_URL"
```

Confirm that the response is media rather than HTML, and record `Content-Length` and `Accept-Ranges` when present.

For an expiring signed URL, refresh the URL and resume only when it identifies the same media object and the server supports byte ranges. Start with one connection. Use fragment concurrency for segmented manifests; increase direct-object connections only when the server tolerates it. If parallel requests trigger throttling, return to short sequential resumable requests with fresh URLs.

Report progress for long transfers using completed bytes, expected bytes, current speed, and destination. Preserve partial data when retrying.

## Verify

Do not report success until the finished file is validated:

```bash
file "$OUTPUT_FILE"
ffprobe -v error \
  -show_entries format=format_name,duration,size \
  -show_entries stream=index,codec_type,codec_name,width,height \
  -of default=noprint_wrappers=1 "$OUTPUT_FILE"
shasum -a 256 "$OUTPUT_FILE"
```

Require a recognized media container, at least one video stream, plausible duration and dimensions, and audio when expected. Compare the final byte count with trusted source metadata or `Content-Length` when available. Treat a local hash as an identifier unless the source provides a trusted hash for comparison.
