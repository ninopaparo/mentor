defmodule MentorWeb.MentorLive do
  use MentorWeb, :live_view

  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} />

    <div class="relative isolate px-6 pt-10 lg:px-8">
      <div>
        <div class="text-center">
          <h1 class="text-4xl font-bold text-gray-900 dark:text-slate-100 sm:text-6xl">
            Mentor
          </h1>
        </div>
      </div>
    </div>
    <div class="max-w-3xl mx-auto p-4 bg-white rounded shadow-md">
      <h1 class="text-lg font-bold mb-2">Welcome</h1>
      <form phx-submit="submit" id="prompt-form" class="flex flex-col gap-4">
        <input
          type="text"
          name="prompt"
          id="prompt"
          class="block w-full "
          placeholder="Please enter your question"
        />
        <button class="bg-green-400 hover:bg-green-500btext-white font-bold py-2 rounded">
          Submit
        </button>
      </form>
      <div id="answer" class="max-w-3xl mx-auto p-4 bg-white rounded shadow-md">
        answer: <%= @answer %>
      </div>
    </div>
    <div class="max-w-3xl mx-auto p-4 bg-white rounded shadow-md">
      <h1 class="text-lg font-bold mb-2">Settings</h1>
      <div class="bg-gray-200">
        ollama REST API: <%= @endpoint %>
      </div>
      <div class="bg-gray-200">
        ollama model: qwen2.5-coder:3b
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:text, "")
      |> assign(:answer, "")
      |> assign(:endpoint, Application.get_env(:mentor, :ollama_endpoint))

    {:ok, socket}
  end

  # When the client invokes the "submit" event, create a streaming request and
  # asynchronously send messages back to self.
  def handle_event("submit", %{"prompt" => prompt}, socket) do
    IO.inspect(prompt)

    {:ok, task} =
      Ollama.completion(Ollama.init(Application.get_env(:mentor, :ollama_endpoint)),
        model: "qwen2.5-coder:3b",
        prompt: prompt,
        stream: self()
      )

    {:noreply, assign(socket, current_request: task)}
  end

  def handle_info({_request_pid, {:data, _data}} = message, socket) do
    pid = socket.assigns.current_request.pid

    case message do
      {^pid, {:data, %{"done" => false} = data}} ->
        # Process each chunk of streaming data
        # IO.puts("Processing chunk: #{inspect(data)}")
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
    {:noreply, assign(socket, current_request: nil, answer: answer)}
  end

  # utility functions
  defp convert_to_markdown(text) do
    String.trim(text) |> Earmark.as_html!() |> Phoenix.HTML.raw()
  end
end
