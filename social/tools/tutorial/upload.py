"""Upload a released website tutorial to Google Drive (rclone).

    python3 social/tools/tutorial/upload.py <NN-game> [--dest gdrive:Tutorials]

Copies the release set from social/out/release/<NN-game>/ (video.mp4,
thumbnail.jpg, post.md) to <dest>/<NN-game>/ on Drive. Re-running replaces
changed files and skips unchanged ones. Needs the `gdrive:` rclone remote
(`rclone config`).
"""

import shutil
import subprocess
import sys
from pathlib import Path

SOCIAL = Path(__file__).resolve().parents[2]
FILES = ["video.mp4", "thumbnail.jpg", "post.md"]


def main() -> None:
    if len(sys.argv) < 2 or sys.argv[1].startswith("-"):
        sys.exit(__doc__)
    folder = sys.argv[1]
    dest = sys.argv[sys.argv.index("--dest") + 1] if "--dest" in sys.argv else "gdrive:Tutorials"
    out = SOCIAL / "out" / "release" / folder
    files = [f for f in FILES if (out / f).exists()]
    missing = [f for f in FILES if f not in files]
    if not files:
        sys.exit(f"nothing to upload in {out} (npm run release -- {folder} <thumb-seconds> first)")
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
