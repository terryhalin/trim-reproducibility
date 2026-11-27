# Shared settings for the package scripts. Sourced (not run) from the package root.
# Defaults follow the README layout. Override any of them with environment variables, e.g.
#   TRIM_DIR=~/trim VENV_DIR=~/trim/.venv TRIMLIB_DIR=~/trim-logs/patched-src/python scripts/smoke_test.sh

TRIM_DIR="${TRIM_DIR:-./TRIM}"                 # upstream clone at 481811b7 (+ fixes.patch)
VENV_DIR="${VENV_DIR:-./.venv}"                # Python virtual environment (README Step 3)
TRIMLIB_DIR="${TRIMLIB_DIR:-$TRIM_DIR/python}" # folder holding the built trimlib*.so (README Step 4)
GIST_PATH="${GIST_PATH:-./data/gist-960.hdf5}" # README Step 6
GIST_BYTES=3933056096

die() { echo "ERROR: $*" >&2; exit 1; }

[ -f "$VENV_DIR/bin/activate" ] || die "no virtual environment at $VENV_DIR (README Step 3)"
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"
[ -f "$TRIM_DIR/bench/bench.py" ] || die "no upstream clone at $TRIM_DIR (README Step 1)"
compgen -G "$TRIMLIB_DIR/trimlib*.so" > /dev/null || die "no trimlib*.so in $TRIMLIB_DIR (README Step 4)"

export PYTHONPATH="$TRIMLIB_DIR${PYTHONPATH:+:$PYTHONPATH}"  # use the built trimlib; no setup.py install
export PYTHONDONTWRITEBYTECODE=1                            # keep __pycache__ out of the upstream clone
# 16 threads for OpenMP (FAISS index training). bench/trim.py's own num_threads = os.cpu_count()-2 is
# left unchanged (known issue 1 in README); it only affects index loading. Queries are single-threaded.
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-16}"

refuse_if_running() {
  if pgrep -f "bench/bench.py" > /dev/null; then
    die "another bench.py is already running (pgrep -af bench/bench.py). Wait for it: parallel runs distort QPS."
  fi
}

require_gist() {
  [ -f "$GIST_PATH" ] || die "GIST file not found at $GIST_PATH (README Step 6, or set GIST_PATH)"
  local size; size=$(stat -c %s "$GIST_PATH")
  [ "$size" = "$GIST_BYTES" ] || die "$GIST_PATH is $size bytes, expected $GIST_BYTES"
}

refuse_if_exists() {
  [ ! -e "$1" ] || die "$1 already exists; bench.py would append to it. Move it away to rerun."
}

write_env() {  # $1 = output file
  {
    echo "date: $(date -Is)"
    echo "host: $(uname -a)"
    echo "cpu: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ //')"
    echo "nproc: $(nproc)"
    free -h | sed 's/^/mem: /'
    echo "os: $(. /etc/os-release && echo "$PRETTY_NAME")"
    echo "upstream commit: $(git -C "$TRIM_DIR" rev-parse HEAD 2>/dev/null || echo UNKNOWN)"
    echo "upstream diff vs commit:"; git -C "$TRIM_DIR" diff --stat 2>/dev/null | sed 's/^/  /'
    echo "trimlib: $(ls "$TRIMLIB_DIR"/trimlib*.so)"
    echo "GIST_PATH: $GIST_PATH"
    echo "OMP_NUM_THREADS: $OMP_NUM_THREADS"
    echo "python: $(python3 --version 2>&1)"
    pip list 2>/dev/null | grep -iE '^(numpy|pandas|scipy|h5py|faiss-cpu|hnswlib|pybind11) ' | sed 's/^/  /'
  } > "$1"
}
