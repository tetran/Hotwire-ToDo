require "test_helper"

class SuggestionLlmServiceTest < ActiveSupport::TestCase
  setup do
    @session = suggestion_sessions(:one)
    @model = llm_models(:gpt_turbo)
    @prompt_set = prompt_sets(:general)

    SuggestionConfig.update_all(active: false)
    @config = SuggestionConfig.create_with_entries!(
      entries_attributes: [{ llm_model_id: @model.id, prompt_set_id: @prompt_set.id, weight: 100 }],
    )
    @entry = @config.entries.first

    @variables = {
      goal: "Build an app",
      context: "iOS development",
      start_date: "2024-01-08",
      due_date: "2024-01-15",
    }

    @valid_json = '{"tasks":[{"name":"Task 1","description":"Do something","due_date":"2024/01/10"}]}'
    @valid_response = { content: @valid_json, model: "gpt-3.5-turbo", usage: { input_tokens: 100, output_tokens: 50 } }
  end

  # === Successful call ===

  test "returns normalized response on first successful attempt" do
    mock_client = build_mock_client
    mock_client.expects(:chat).once.returns(@valid_response)
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    service = SuggestionLlmService.new(entry: @entry, session: @session, variables: @variables)
    result = service.call

    assert_not_nil result
    assert_equal @valid_json, result[:content]
    assert_equal 100, result[:usage][:input_tokens]
  end

  test "creates SuggestionRequest for each attempt" do
    mock_client = build_mock_client
    mock_client.expects(:chat).once.returns(@valid_response)
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    service = SuggestionLlmService.new(entry: @entry, session: @session, variables: @variables)

    assert_difference "SuggestionRequest.count", 1 do
      service.call
    end

    request = SuggestionRequest.last
    assert_equal @session, request.suggestion_session
    assert_equal @entry, request.suggestion_config_entry
    assert_not_nil request.raw_request
  end

  test "built messages include rendered prompts from prompt set" do
    mock_client = build_mock_client
    mock_client.expects(:chat).once.with do |args|
      messages = args[:messages]
      messages.any? { |m| m[:content].include?("Build an app") }
    end.returns(@valid_response)
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    service = SuggestionLlmService.new(entry: @entry, session: @session, variables: @variables)
    service.call
  end

  # === Retry on JSON parse failure ===

  test "retries on JSON parse failure and succeeds on second attempt" do
    mock_client = build_mock_client
    mock_client.expects(:chat).twice.returns(
      { content: "Not valid JSON at all", model: "gpt-3.5-turbo", usage: { input_tokens: 50, output_tokens: 20 } },
    ).then.returns(@valid_response)
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    service = SuggestionLlmService.new(entry: @entry, session: @session, variables: @variables)

    assert_difference "SuggestionRequest.count", 2 do
      result = service.call
      assert_not_nil result
      assert_equal @valid_json, result[:content]
    end
  end

  # === Retry on schema validation failure ===

  test "retries when JSON is valid but missing required keys" do
    invalid_schema = '{"tasks":[{"title":"Missing name key"}]}'
    mock_client = build_mock_client
    mock_client.expects(:chat).twice.returns(
      { content: invalid_schema, model: "gpt-3.5-turbo", usage: { input_tokens: 50, output_tokens: 20 } },
    ).then.returns(@valid_response)
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    service = SuggestionLlmService.new(entry: @entry, session: @session, variables: @variables)
    result = service.call

    assert_not_nil result
  end

  # === All retries fail ===

  test "returns nil when all 3 attempts fail" do
    mock_client = build_mock_client
    mock_client.expects(:chat).times(3).returns(
      { content: "invalid", model: "gpt-3.5-turbo", usage: { input_tokens: 10, output_tokens: 5 } },
    )
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    service = SuggestionLlmService.new(entry: @entry, session: @session, variables: @variables)

    assert_difference "SuggestionRequest.count", 3 do
      result = service.call
      assert_nil result
    end
  end

  test "retries when response content is nil and succeeds on next attempt" do
    mock_client = build_mock_client
    mock_client.expects(:chat).twice.returns(
      { content: nil, model: "gpt-3.5-turbo", usage: { input_tokens: 50, output_tokens: 20 } },
    ).then.returns(@valid_response)
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    service = SuggestionLlmService.new(entry: @entry, session: @session, variables: @variables)
    result = service.call

    assert_not_nil result
    assert_equal @valid_json, result[:content]
  end

  # === ApiError — no retry ===

  test "does not retry on LlmClient::ApiError" do
    mock_client = build_mock_client
    mock_client.expects(:chat).once.raises(LlmClient::ApiError.new("Unauthorized", 401))
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    service = SuggestionLlmService.new(entry: @entry, session: @session, variables: @variables)

    assert_difference "SuggestionRequest.count", 1 do
      result = service.call
      assert_nil result
    end
  end

  # === Temperature changes across retries ===

  test "uses decreasing temperature across retries" do
    temperatures = []
    mock_client = build_mock_client
    mock_client.expects(:chat).times(3).with do |args|
      temperatures << args[:temperature]
      true
    end.returns(
      { content: "bad", model: "gpt-3.5-turbo", usage: { input_tokens: 10, output_tokens: 5 } },
    )
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    service = SuggestionLlmService.new(entry: @entry, session: @session, variables: @variables)
    service.call

    assert_equal 0.7, temperatures[0]
    assert_equal 0.3, temperatures[1]
    assert_equal 0.3, temperatures[2]
  end

  # === Instrumentation ===

  test "instruments chat.llm for each attempt with detailed payload" do
    mock_client = build_mock_client
    mock_client.expects(:chat).once.returns(@valid_response)
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    events = []
    callback = ->(*args) { events << ActiveSupport::Notifications::Event.new(*args) }
    ActiveSupport::Notifications.subscribed(callback, "chat.llm") do
      service = SuggestionLlmService.new(entry: @entry, session: @session, variables: @variables)
      service.call
    end

    assert_equal 1, events.size
    payload = events.first.payload
    assert_equal @session.id, payload[:session_id]
    assert_equal @entry.llm_model.llm_provider.name, payload[:provider]
    assert_equal @entry.llm_model.name, payload[:model]
    assert_equal @entry.prompt_set.name, payload[:prompt_set]
    assert_equal @entry.id, payload[:config_entry_id]
    assert_equal 1, payload[:attempt]
    assert_equal true, payload[:success]
  end

  test "instruments chat.llm per retry attempt" do
    mock_client = build_mock_client
    mock_client.expects(:chat).twice.returns(
      { content: "bad json", model: "gpt-3.5-turbo", usage: { input_tokens: 10, output_tokens: 5 } },
    ).then.returns(@valid_response)
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    events = []
    callback = ->(*args) { events << ActiveSupport::Notifications::Event.new(*args) }
    ActiveSupport::Notifications.subscribed(callback, "chat.llm") do
      service = SuggestionLlmService.new(entry: @entry, session: @session, variables: @variables)
      service.call
    end

    assert_equal 2, events.size
    assert_equal 1, events[0].payload[:attempt]
    assert_equal false, events[0].payload[:success]
    assert_equal 2, events[1].payload[:attempt]
    assert_equal true, events[1].payload[:success]
  end

  test "instruments chat.llm with success false on ApiError" do
    mock_client = build_mock_client
    mock_client.expects(:chat).once.raises(LlmClient::ApiError.new("Unauthorized", 401))
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    events = []
    callback = ->(*args) { events << ActiveSupport::Notifications::Event.new(*args) }
    ActiveSupport::Notifications.subscribed(callback, "chat.llm") do
      service = SuggestionLlmService.new(entry: @entry, session: @session, variables: @variables)
      service.call
    end

    assert_equal 1, events.size
    assert_equal false, events.first.payload[:success]
  end

  # === Structured output options ===

  test "adds response_format option for OpenAI requests" do
    mock_client = build_mock_client(
      json_output_options: {
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "emit_tasks_json",
            schema: { type: "object" },
            strict: true,
          },
        },
      },
    )
    mock_client.expects(:json_output_options).once.with do |args|
      assert_equal true, args[:json_only]
      assert_equal true, args.dig(:structured_output, :enabled)
      assert_equal true, args.dig(:structured_output, :strict)
      assert_equal "emit_tasks_json", args.dig(:structured_output, :schema_name)
      assert_equal false, args.dig(:structured_output, :schema, :additionalProperties)
      assert_equal false, args.dig(:structured_output, :schema, :properties, :tasks, :items, :additionalProperties)
      true
    end.returns(
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "emit_tasks_json",
          schema: { type: "object" },
          strict: true,
        },
      },
    )
    mock_client.expects(:chat).once.with do |args|
      assert_equal "json_schema", args.dig(:response_format, :type)
      true
    end.returns(@valid_response)
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    service = SuggestionLlmService.new(entry: @entry, session: @session, variables: @variables)
    service.call
  end

  test "adds response mime type option for Gemini requests" do
    gemini_provider = LlmProvider.create!(
      name: "Gemini",
      api_key: "gemini-test-key",
      active: true,
    )
    gemini_model = LlmModel.create!(
      llm_provider: gemini_provider,
      name: "gemini-2.5-flash",
      display_name: "Gemini 2.5 Flash",
      active: true,
      default_model: true,
    )
    gemini_config = SuggestionConfig.create_with_entries!(
      entries_attributes: [{ llm_model_id: gemini_model.id, prompt_set_id: @prompt_set.id, weight: 100 }],
    )
    gemini_entry = gemini_config.entries.first

    mock_client = build_mock_client(
      json_output_options: {
        generation_config: {
          "responseMimeType" => "application/json",
          "responseJsonSchema" => { "type" => "object" },
        },
      },
    )
    mock_client.expects(:chat).once.with do |args|
      assert_equal "application/json", args.dig(:generation_config, "responseMimeType")
      assert_equal({ "type" => "object" }, args.dig(:generation_config, "responseJsonSchema"))
      true
    end.returns(@valid_response)
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    service = SuggestionLlmService.new(entry: gemini_entry, session: @session, variables: @variables)
    service.call
  end

  test "adds tool choice options for Anthropic requests" do
    claude_model = llm_models(:claude)
    claude_config = SuggestionConfig.create_with_entries!(
      entries_attributes: [{ llm_model_id: claude_model.id, prompt_set_id: @prompt_set.id, weight: 100 }],
    )
    claude_entry = claude_config.entries.first

    mock_client = build_mock_client(
      json_output_options: {
        output_config: { format: { type: "json_schema", schema: { type: "object" } } },
      },
    )
    mock_client.expects(:chat).once.with do |args|
      assert_equal "json_schema", args.dig(:output_config, :format, :type)
      assert_equal({ type: "object" }, args.dig(:output_config, :format, :schema))
      true
    end.returns(@valid_response)
    LlmClientFactory.stubs(:create_client_from_model).returns(mock_client)

    service = SuggestionLlmService.new(entry: claude_entry, session: @session, variables: @variables)
    service.call
  end

  private

    def build_mock_client(json_output_options: {})
      mock_client = mock("llm_client")
      mock_client.stubs(:json_output_options).returns(json_output_options)
      mock_client
    end
end
