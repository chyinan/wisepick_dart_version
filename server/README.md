# wisepick proxy server

This small Dart `shelf` proxy forwards requests from the Flutter app to an OpenAI-compatible API provider.

Environment variables
- `OPENAI_API_KEY` (required): API key to forward in `Authorization: Bearer <key>`
- `OPENAI_API_URL` (optional): upstream URL, defaults to `https://api.openai.com/v1/chat/completions`
- `PORT` (optional): server port, defaults to `8080`

Run locally

1. cd into `server`
2. `dart pub get`
3. `OPENAI_API_KEY=sk-... dart run bin/proxy_server.dart`

Configure Flutter app

In `lib/features/chat/chat_service.dart`, replace the mock implementation with a POST to `http://localhost:8080/v1/chat/completions` and forward the OpenAI-compatible request body. Keep using `ApiClient` or `http` as you prefer.

Notes

- This proxy does not implement streaming responses. For streaming, additional handling is required.
- For production, restrict origins and add authentication.