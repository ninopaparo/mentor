# Mentor

## Phoenix Liveview application to leverage LLMs

This project is part of [Hack Week 24](https://hackweek.opensuse.org/projects/learn-how-to-integrate-elixir-and-phoenix-liveview-with-llms), to learn how to integrate Elixir and the Phoenix Framework with Large Language Models

### Requirements

- [Elixir](https://elixir-lang.org/)
- [Phoenix Framework](https://www.phoenixframework.org/)
- [Ollama](https://ollama.com/)

### Usage - development

- Create an `.env` file and update the `OLLAMA_API_ENDPOINT=` with the base URL of the `ollama` server
- Run `source .env` and `mix phx.server`
- Open `http://127.0.0.1:4000/`

### Features

- [x] Integrate with ollama
- [x] Render Markdown
- [x] Select LLMs
