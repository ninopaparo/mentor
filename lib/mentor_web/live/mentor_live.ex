defmodule MentorWeb.MentorLive do
  use MentorWeb, :live_view
  attr :current_model, :string, default: ""

  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} />

    <div class="relative isolate px-6 pt-10 lg:px-8">
      <div>
        <div class="text-center">
          <h1 class="text-4xl font-bold text-gray-900 sm:text-6xl">
            Mentor
          </h1>
        </div>
      </div>
    </div>
    <div class="max-w-3xl mx-auto p-4 bg-white rounded shadow-md">
      <h1 class="text-lg font-bold mb-2">Welcome</h1>
      <form phx-submit="submit" phx-change="select" id="prompt-form" class="flex flex-col gap-4">
        <input
          type="text"
          name="prompt"
          id="prompt"
          class="block w-full "
          placeholder="Please enter your question"
        />
        <select name="model_id" id="model_id">
          <%= for model <- @available_models do %>
            <option value={model} selected><%= model %></option>
          <% end %>
        </select>
        <button class="bg-green-400 hover:bg-green-500btext-white font-bold py-2 rounded">
          Submit
        </button>
      </form>
      <div id="answer" class="max-w-3xl mx-auto p-4 bg-white rounded shadow-md">
        <%= if @loading do %>
          Please wait... <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
        <% end %>
        <%= @answer %>
      </div>
    </div>
    <div class="max-w-3xl mx-auto p-4 bg-white rounded shadow-md">
      <h1 class="text-lg font-bold mb-2">Settings</h1>
      <div class="bg-gray-200">
        <%= if @endpoint do %>
          ollama API : <%= @endpoint %>
        <% end %>
        <%= if !@endpoint do %>
          ollama is running on localhost
        <% end %>
      </div>
      <div class="bg-gray-200">
        <%= if @current_model != "" do %>
          ollama model: <%= @current_model %>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:answer, "")
      |> assign(:endpoint, Application.get_env(:mentor, :ollama_endpoint))
      |> assign(:available_models, list_available_models())
      |> assign(:loading, false)

    {:ok, socket}
  end

  def handle_event("select", %{"model_id" => model_id}, socket) do
    {:noreply, assign(socket, :current_model, model_id)}
  end

  def handle_event("submit", %{"prompt" => prompt, "model_id" => model_id}, socket) do
    send(self(), {:exec_query, prompt, model_id})
    {:noreply, assign(socket, loading: true, answer: "")}
  end

  def handle_info({:exec_query, prompt, model_id}, socket) do
    client = create_ollama_client()

    {:ok, task} =
      Ollama.completion(client,
        model: model_id,
        prompt: prompt,
        stream: self()
      )

    socket =
      socket
      |> assign(:current_request, task)
      |> assign(:current_model, model_id)

    {:noreply, socket}
  end

  def handle_info({_request_pid, {:data, _data}} = message, socket) do
    pid = socket.assigns.current_request.pid

    case message do
      {^pid, {:data, %{"done" => false} = data}} ->
        # Process each chunk of streaming data
        IO.puts(data["response"])

      {^pid, {:data, %{"done" => true} = data}} ->
        # Handle the final stream
        IO.puts("Final streaming chunk received: #{inspect(data)}")

      {_pid, _data} ->
        # Unexpected message
        IO.inspect("Unexpected message: #{message}")
    end

    {:noreply, socket}
  end

  def handle_info({ref, {:ok, resp}}, socket) do
    answer = convert_to_markdown(resp["response"])
    Process.demonitor(ref, [:flush])
    {:noreply, assign(socket, current_request: nil, answer: answer, loading: false)}
  end

  # utility functions
  defp create_ollama_client() do
    case Application.get_env(:mentor, :ollama_endpoint) do
      nil ->
        Ollama.init()

      _ ->
        Ollama.init(Application.get_env(:mentor, :ollama_endpoint))
    end
  end

  def list_available_models() do
    client = create_ollama_client()
    {:ok, models} = Ollama.list_models(client)
    Enum.map(models["models"], &Map.get(&1, "model"))
  end

  defp convert_to_markdown(text) do
    String.trim(text) |> Earmark.as_html!() |> Phoenix.HTML.raw()
  end
end
