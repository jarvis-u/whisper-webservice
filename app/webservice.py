import importlib.metadata
import os

import numpy as np

import ffmpeg

from typing import Union, Annotated, BinaryIO

from fastapi import FastAPI, File, UploadFile, Query
from fastapi.responses import StreamingResponse
from whisper import tokenizer
from urllib.parse import quote

SAMPLE_RATE = 16000

LANGUAGE_CODES = sorted(list(tokenizer.LANGUAGES.keys()))

ASR_ENGINE = os.getenv("ASR_ENGINE", "openai_whisper")
if ASR_ENGINE == "faster_whisper":
    from .faster_whisper.core import transcribe
else:
    from .openai_whisper.core import transcribe

app = FastAPI()


@app.post("/translation")
async def translation(
        audio_file: UploadFile = File(...),
        encode: bool = Query(default=True, description="Encode audio first through ffmpeg"),
        language: Union[str, None] = Query(default="zh", enum=LANGUAGE_CODES),
        initial_prompt: Union[str, None] = Query(default="以下是普通话的句子。"),
        vad_filter: Annotated[bool | None, Query(
            description="Enable the voice activity detection (VAD) to filter out parts of the audio without speech",
            include_in_schema=(True if ASR_ENGINE == "faster_whisper" else False)
        )] = False,
        output: Union[str, None] = Query(default="txt", enum=["txt", "vtt", "srt", "tsv", "json"])
):
    result = transcribe(load_audio(audio_file.file, encode), language, initial_prompt, vad_filter, output)
    return StreamingResponse(
        result,
        media_type="text/plain",
        headers={
            'Asr-Engine': ASR_ENGINE,
            'Content-Disposition': f'attachment; filename="{quote(audio_file.filename)}.{output}"'
        }
    )


def load_audio(file: BinaryIO, encode=True, sr: int = SAMPLE_RATE):
    """
    Open an audio file object and read as mono waveform, resampling as necessary.
    Modified from https://github.com/openai/whisper/blob/main/whisper/audio.py to accept a file object
    Parameters
    ----------
    file: BinaryIO
        The audio file like object
    encode: Boolean
        If true, encode audio stream to WAV before sending to whisper
    sr: int
        The sample rate to resample the audio if necessary
    Returns
    -------
    A NumPy array containing the audio waveform, in float32 dtype.
    """
    if encode:
        try:
            out, _ = (
                ffmpeg.input("pipe:", threads=0)
                .output("-", format="s16le", acodec="pcm_s16le", ac=1, ar=sr)
                .run(cmd="ffmpeg", capture_stdout=True, capture_stderr=True, input=file.read())
            )
        except ffmpeg.Error as e:
            raise RuntimeError(f"Failed to load audio: {e.stderr.decode()}") from e
        except Exception as e:
            raise f"error {e}"
    else:
        out = file.read()

    # float32 from -32768 ~ 32767
    return np.frombuffer(out, np.int16).flatten().astype(np.float32) / 32768.0
