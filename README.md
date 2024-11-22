# Mentor

## Phoenix Liveview application to leverage LLMs

This project is part of [Hack Week 24](https://hackweek.opensuse.org/projects/learn-how-to-integrate-elixir-and-phoenix-liveview-with-llms), to learn how to integrate Elixir and the Phoenix Framework with Large Language Models

### Requirements

- [Elixir](https://elixir-lang.org/)
- [Phoenix Framework](https://www.phoenixframework.org/)
- [Ollama](https://ollama.com/)

### How to setup the development environment

- clone the [mentor](https://github.com/ninopaparo/mentor) project
- cd into the `mentor` directory
- run `mix deps.get` and `iex -S mix phx.server`
  - _optional_ To leverage a remote _ollama_ instance, please create an `.env` file and update the `OLLAMA_API_ENDPOINT=` variable and run `source .env`
- Open `http://127.0.0.1:4000/`

### Features

- [x] Integrate with ollama
- [x] Render Markdown
- [x] Select LLMs
- [ ] Retrieval Augmented Generation (RAG)
