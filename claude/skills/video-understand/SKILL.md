---
name: video-understand
description: Understands a video (mp4 and others) locally. Claude cannot read video or audio directly, so this splits it with ffmpeg + whisper.cpp into two channels — audio → timestamped transcript and video → still frames — and merges them on one timeline. Transcription is local and free (whisper.cpp). Includes setup on Arch, model choice and token-cost control. Triggers on "read this video", "analiza este video", "transcribe this", "what is in this mp4".
user-invocable: true
---

# Video understanding (ffmpeg + whisper.cpp)

Claude Code's Read tool reads images (PNG/JPG), PDFs and text, but **not video (mp4/mov and so on) or audio**. This skill preprocesses the video into forms Claude can read.

A video's information lives in two channels, and **picking up both raises the resolution of understanding**:

1. **Audio → text**: extract the audio with `ffmpeg` and transcribe it with timestamps using `whisper.cpp`. Captures what is said (narration, meetings, explanations). **This is usually the densest channel.**
2. **Video → still frames**: extract frames with `ffmpeg` and read them as PNG with Read. Captures what is shown (screens, slides, UI, people, scenes).

Finally, **merge the transcript (with times) and the frames (with times) on one timeline**.

## Preconditions

Meet all of these before the main work. Set up whatever is missing as below.

- **`ffmpeg` / `ffprobe` installed** (`command -v ffmpeg ffprobe`). If not: `sudo pacman -S ffmpeg`.
- **`whisper-cli` installed** (`command -v whisper-cli`). If not, the `whisper-cpp` package in Arch `extra` provides `/usr/bin/whisper-cli`. Claude cannot run sudo, so ask the user to run `! sudo pacman -S whisper-cpp`.
  - Do not use the Python whisper (`openai-whisper` / `python-openai-whisper`). It pulls in torch and bloats the environment. whisper.cpp has no Python dependency, is free and runs fully locally.
- **A GGML model file exists** (below). whisper.cpp ships no model, so the first run needs a download.

### Getting a whisper.cpp model

Models live in `~/.local/share/whisper-models/` by convention. **Use the multilingual ones (without `.en`)** — `ggml-base.en.bin` and other `.en` files are English-only and will not transcribe Spanish.

```bash
mkdir -p ~/.local/share/whisper-models
# Default: multilingual base (~148MB, fast, decent accuracy)
curl -L -o ~/.local/share/whisper-models/ggml-base.bin \
  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
```

Model choice (accuracy vs. size/speed trade-off; **for accuracy outside English, large-v3-turbo is recommended**):

| Model file | Size | Use |
|---|---|---|
| `ggml-base.bin` | ~148MB | Default. Fast. Enough for English or clear audio |
| `ggml-small.bin` | ~488MB | When base is not accurate enough. Balanced for Spanish |
| `ggml-large-v3-turbo.bin` | ~1.6GB | **Accuracy first, especially outside English.** Turbo keeps large-class models at practical speed |

Download URL: `https://huggingface.co/ggerganov/whisper.cpp/resolve/main/<file name>`. Before moving up from the default model, confirm with the user, since size and time change.

## How to run it

Make a work directory (`$TMPDIR/video-understand/<name>/`, inside the session scratchpad when there is one) and write intermediate files there. Never put intermediate files in the repository.

### 1. Read the metadata and pick a sampling plan

First check duration, resolution, fps and whether there is an audio track. That decides the frame count and the plan.

```bash
ffprobe -v error -show_entries format=duration:stream=index,codec_type,codec_name,width,height,r_frame_rate \
  -of default=noprint_wrappers=1 input.mp4
```

- `duration` sets the frame budget (see cost control below).
- If there is no audio stream (`codec_type=audio`), skip transcription and work from the video channel only.

### 2. Extract the audio and transcribe

whisper.cpp expects **16kHz mono wav**. Convert with `ffmpeg` before passing it in.

```bash
MODEL=~/.local/share/whisper-models/ggml-base.bin
# Convert to 16kHz mono wav
ffmpeg -y -i input.mp4 -vn -ar 16000 -ac 1 -c:a pcm_s16le audio.wav
# Transcribe (SRT = timestamped, easy for Claude to read). -l auto detects the language
whisper-cli -m "$MODEL" -f audio.wav -l auto -osrt -of transcript
# → writes transcript.srt. Read that
```

- `-l auto` detects the language. If you know it is Spanish, pass `-l es`; English, `-l en`. Explicit is more stable.
- Besides `-osrt` (SRT), there are `-oj` (JSON, structured), `-otxt` (plain) and `-ovtt`. **Use a timestamped format (SRT/JSON) so times can be matched to frames.**
- whisper-cli prints lots of progress and backend info to stdout/stderr, but **the result goes to the file named by `-of`**. Do not parse stdout; Read the generated `transcript.srt`.

### 3. Extract frames

**Try scene-change detection first, and fall back to a fixed interval if it is not enough.**

```bash
mkdir -p frames
# Method A: scene-change detection (good for slide changes and cuts; cuts redundant frames sharply)
ffmpeg -y -i input.mp4 -vf "select='gt(scene,0.3)',scale=768:-1" -fps_mode vfr frames/scene_%04d.png

# Method B: fixed interval (when scene detection yields 0 frames or the footage is continuous). E.g. 1 frame / 5 s
ffmpeg -y -i input.mp4 -vf "fps=1/5,scale=768:-1" frames/frame_%04d.png
```

- `scale=768:-1` **shrinks to 768px wide**. Claude's image tokens scale with resolution, so shrink as far as text stays readable (go larger only when you need to read small slide text).
- After extracting, count the frames; if there are too many or too few, adjust the threshold (`scene,0.3`) or interval (`fps=1/N`) and extract again.
- Open each PNG with Read and describe what is visible (do not invent). **File order = extraction order ≈ time order**, so frames line up with the SRT times.

### 4. Merge and answer

Merge the transcript (SRT times) and the frames (time order) into one timeline: "when, what was shown, what was said". Shape the output to the user's question (summary, extracting a specific part, explaining a UI and so on).

## Token-cost control (most important)

Reading a frame = image understanding = tokens. One frame per second of a 10-minute video is 600 frames and instant bankruptcy. **Always thin the sampling according to duration.**

Guideline (768px wide, varies with content; **if it looks like landing on the high side, tell the user the frame count and cost before extracting**):

| Duration | Frame count | Plan |
|---|---|---|
| up to 1 min | 5-12 | Scene detection or every 5-10 s |
| 1-10 min | 12-30 | Prefer scene detection; on interval, every 20-30 s |
| 10 min+ | ~30 as a cap | Widen the interval. If full coverage is needed, **propose splitting into segments** |

- The default cap is about **24-30 frames**. If you would exceed it, do not silently extract a lot; present the count, aim and cost, and ask.
- A transcript costs tokens in proportion to duration, but far less than images. **For long videos, get the overview from the transcript first, then extract frames only at the key timestamps.**

## Traps

Verified 2026-10-25 on this machine (ffmpeg 9.0.1):

- **ffmpeg 9 removed `-vsync`**: `-vsync vfr` fails with `Unrecognized option 'vsync'`. Use `-fps_mode vfr`.
- **Scene detection can yield 0 frames**: footage with no hard cuts (gradients, smooth motion, synthetic video, a zoom over a single image) makes `select='gt(scene,...)'` pick nothing. If detection returns 0 or very few frames, **fall back to method B (fixed interval)**. It works on real footage with slides or cuts.
- **No audio track**: if `ffprobe` shows no audio stream, skip transcription (`ffmpeg -vn` fails). Work from the video channel only.

Reported by the original author (whisper-cpp 1.9.1 on macOS), not re-run here yet:

- **`.en` models are English-only**: use a multilingual model (`ggml-base.bin` and so on, without `.en`) for anything else.
- **whisper hallucinates on silence and music**: during sections with no speech it may repeat the same line or invent plausible sentences. On videos with long silences, do not take the transcript at face value; distrust unnatural repetition.
- **whisper-cli stdout is noisy**: lines like `load_backend:` and `read_audio_data:` are not the result. The file written by `-of` (`transcript.srt` and so on) is.
- **Without a downloaded model it fails immediately**: whisper.cpp ships no model; a fresh install always needs a model download.
- **Large images waste tokens**: do not extract at full size; shrink with `scale=768:-1`. Raise the resolution only when small slide text must be read.
