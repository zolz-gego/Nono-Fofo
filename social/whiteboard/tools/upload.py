"""Upload a released whiteboard letter video to Google Drive (rclone).

    python3 social/whiteboard/tools/upload.py <folder> [--dest gdrive:Whiteboard]

Copies the release set from social/whiteboard/out/<folder>/ (video.mp4,
thumbnail.jpg, story.mp4, post.md; never draft.mp4) to <dest>/<folder>/ on
Drive. Re-running replaces changed files and skips unchanged ones. Needs the
`gdrive:` rclone remote (`rclone config`).
"""

import shutil
import subprocess
import sys
from pathlib import Path

WHITEBOARD = Path(__file__).resolve().parents[1]
FILES = ["video.mp4", "thumbnail.jpg", "story.mp4", "post.md"]


def main() -> None:
    if len(sys.argv) < 2 or sys.argv[1].startswith("-"):
        sys.exit(__doc__)
    folder = sys.argv[1]
    dest = sys.argv[sys.argv.index("--dest") + 1] if "--dest" in sys.argv else "gdrive:Whiteboard"
    out = WHITEBOARD / "out" / folder
    files = [f for f in FILES if (out / f).exists()]
    missing = [f for f in FILES if f not in files]
    if not files:
        sys.exit(f"nothing to upload in {out}")
    if missing:
        print(f"warning: missing {', '.join(missing)} in {out}")
    if not shutil.which("rclone"):
        sys.exit("rclone not found (brew install rclone, then rclone config)")
    target = f"{dest.rstrip('/')}/{folder}"
    cmd = ["rclone", "copy", str(out), target, "--progress"]
    for f in files:
        cmd += ["--include", f]
    subprocess.run(cmd, check=True)
    print(f"uploaded {', '.join(files)} -> {target}")


if __name__ == "__main__":
    main()
