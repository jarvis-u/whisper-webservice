# 接口说明
```shell
POST /translation

Request Header
  Content-Type: multipart/form-data

Request Body      // 可选，Query Params 指定了 file_path 时不传递 Request Body
  form-data:
    key: audio_file
    value: 需要转译的音频

Query Params
  file_path     // 本地文件路径，可选，传递了 Request Body 后不传递该参数
  language      // 转译的语言类型，可选，默认为 `zh`
  output       // 返回的响应结果，可选，默认为 `txt`，enum("txt", "vtt", "srt", "tsv", "json")
```

# 运行
环境变量：
- ASR_MODEL: 指定运行的模型， enum(`tiny`, `base`, `small`, `medium`, `large`)
## CPU
```shell
docker run -d -p 8080:8080 -e ASR_MODEL=base -v /path/to/localPath:/path/to/containerPath jiachengwu/whisper-webservice:latest-cpu
```
## GPU
```shell
docker run -d --gpus all -p 9000:9000 -e ASR_MODEL=base -v /path/to/localPath:/path/to/containerPath onerahmet/openai-whisper-asr-webservice:latest-gpu
```
