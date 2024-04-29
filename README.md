# 接口说明
```shell
POST /translation

Request Header
  Content-Type: multipart/form-data

Request Body
  form-data:
    key: audio_file
    value: 需要转译的音频

Query Params
  language      // 转译的语言类型，默认为 `zh`
  output       // 返回的响应结果，默认为 `txt`，enum("txt", "vtt", "srt", "tsv", "json")
```

# 运行
环境变量：
- ASR_MODEL: 指定运行的模型， enum(`tiny`, `base`, `small`, `medium`, `large`)
## CPU
```shell
docker run -d -p 8080:8080 -e ASR_MODEL=base jiachengwu/whisper-webservice:latest
```
## GPU
```shell
docker run -d --gpus all -p 9000:9000 -e ASR_MODEL=base -e ASR_ENGINE=openai_whisper onerahmet/openai-whisper-asr-webservice:latest-gpu
```
