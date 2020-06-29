defmodule DrawIt.GameServer do
  @moduledoc """
  A `GenServer` used for managing a game's state.

  To create a game server, start by passing an existing `%DrawIt.Games.Game{}`
  into `start_link/1`.

      {:ok, game} = Games.create_game(%{})
      {:ok, server} = GameServer.start_link(game: game)

  Once the server is created, you can use the returned server pid or the game's
  join_code to interact with the game server.

      {:ok, player1} = GameServer.join(server, %{nickname: "Ben"})
      {:ok, player2} = GameServer.join(game.join_code, %{nickname: "Wendy"})

      {:ok, round} = GameServer.start_round(game.join_code, %{})
      :ok = GameServer.end_round(game.join_code, %{})
  """

  use GenServer

  require Logger

  alias DrawIt.Games
  alias DrawIt.RandomWords

  @server_registry_name :game_server_registry

  defmodule State do
    @moduledoc """
    This module defines a struct that represents the game state for `GameServer`.
    """

    defstruct game: nil,
              current_round: nil,
              player_ids_joined: [],
              player_ids_drawn: [],
              player_ids_correct_guess: []
  end

  ##
  # Client
  ##

  def start_link(options) do
    game = Keyword.fetch!(options, :game)
    name = via_tuple(game.join_code)

    GenServer.start_link(__MODULE__, options, name: name)
  end

  defp via_tuple(join_code), do: {:via, Registry, {@server_registry_name, join_code}}

  def join(join_code, payload) do
    GenServer.call(via_tuple(join_code), {:join, payload})
  end

  def start_round(join_code, payload) do
    GenServer.call(via_tuple(join_code), {:start_round, payload})
  end

  def end_round(join_code, payload) do
    GenServer.call(via_tuple(join_code), {:end_round, payload})
  end

  def guess(join_code, payload) do
    GenServer.call(via_tuple(join_code), {:guess, payload})
  end

  def whereis(join_code) do
    case Registry.lookup(@server_registry_name, join_code) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  ##
  # Server
  ##

  @impl true
  def init(options \\ []) do
    state = %State{
      game: Keyword.fetch!(options, :game)
    }

    set_logger_metadata(state)
    Logger.info("Game server created")

    {:ok, state}
  end

  @impl true
  def handle_call({:join, %{nickname: nickname}}, _from, %State{} = state) do
    set_logger_metadata(state)

    if reached_max_players_joined?(state.game, state.player_ids_joined) do
      Logger.info("Attempted to join, but already reached max players", player: nickname)

      {:reply, {:error, :reached_max_players}, state}
    else
      player = find_or_create_player(state.game, nickname)
      updated_game = Games.get_game!(state.game.id)
      player_ids_joined = add_joined_player(state.player_ids_joined, player)

      Logger.info("Player joined", player: nickname)

      new_state = %State{
        state
        | game: updated_game,
          player_ids_joined: player_ids_joined
      }

      {:reply, {:ok, player}, new_state}
    end
  end

  @impl true
  def handle_call({:start_round, _payload}, _from, %State{current_round: nil} = state) do
    set_logger_metadata(state)

    if reached_max_rounds?(state.game) do
      Logger.info("Attempted to start round, but already reached max rounds")

      {:reply, {:error, :reached_max_rounds}, state}
    else
      {id_player_drawer, player_ids_joined} =
        select_drawer(state.player_ids_drawn, state.player_ids_joined)

      word = RandomWords.word(:easy)

      {:ok, round} =
        Games.create_round(%{
          id_game: state.game.id,
          id_player_drawer: id_player_drawer,
          word: word
        })

      Logger.info("Round started", round_id: round.id)

      new_state = %State{
        state
        | game: Games.get_game!(state.game.id),
          current_round: round,
          player_ids_drawn: player_ids_joined
      }

      {:reply, {:ok, round}, new_state}
    end
  end

  def handle_call({:start_round, _payload}, _from, %State{current_round: %Games.Round{}} = state) do
    set_logger_metadata(state)
    Logger.info("Attempted to start round, but a round was already started")

    {:reply, {:error, :already_started}, state}
  end

  @impl true
  def handle_call({:end_round, _payload}, _from, %State{current_round: current_round} = state) do
    set_logger_metadata(state)
    Logger.info("Round ended", round_id: current_round.id)

    game = Games.get_game!(state.game.id)

    new_state = %State{
      state
      | game: game,
        current_round: nil,
        player_ids_correct_guess: []
    }

    {:reply, {:ok, game}, new_state}
  end

  @impl true
  def handle_call({:guess, %{player: player}}, _from, %State{current_round: nil} = state) do
    set_logger_metadata(state)
    Logger.info("Guess made, but round not started", player: player.nickname)

    {:reply, {:ok, false}, state}
  end

  def handle_call(
        {:guess, %{player: player, guess: guess}},
        _from,
        %State{current_round: current_round} = state
      ) do
    set_logger_metadata(state)
    Logger.info("Guess", correct_word: current_round.word, guess: guess, player_id: player.id)

    correct? = correct_guess?(guess, current_round.word)
    already_guessed? = player.id in state.player_ids_correct_guess

    if !already_guessed? && correct? do
      player = Games.get_player!(player.id)

      Games.update_player(player, %{
        score: player.score + 1
      })

      new_state = %State{
        state
        | player_ids_correct_guess: [player.id | state.player_ids_correct_guess]
      }

      {:reply, {:ok, correct?}, new_state}
    else
      {:reply, {:ok, correct?}, state}
    end
  end

  ##
  # Server Helpers
  ##

  defp set_logger_metadata(%State{game: game}) do
    Logger.metadata(join_code: game.join_code)
  end

  defp find_or_create_player(game, nickname) do
    existing_player = Enum.find(game.players, &(&1.nickname == nickname))

    if existing_player do
      existing_player
    else
      {:ok, player} =
        Games.create_player(%{
          id_game: game.id,
          nickname: nickname
        })

      player
    end
  end

  defp add_joined_player(player_ids_joined, player) do
    already_joined? = Enum.any?(player_ids_joined, &(&1 == player.id))

    if already_joined? do
      player_ids_joined
    else
      [player.id | player_ids_joined]
    end
  end

  defp reached_max_players_joined?(%Games.Game{max_players: max_players}, player_ids_joined) do
    length(player_ids_joined) >= max_players
  end

  defp reached_max_rounds?(%Games.Game{rounds: rounds, max_rounds: max_rounds}) do
    length(rounds) >= max_rounds
  end

  # Reset once everyone has drawn
  defp select_drawer(drawn, joined) when length(drawn) >= length(joined) do
    drawer = Enum.random(joined)
    {drawer, [drawer]}
  end

  defp select_drawer(drawn, joined) do
    drawer =
      joined
      |> Enum.reject(&(&1 in drawn))
      |> Enum.random()

    {drawer, [drawer | drawn]}
  end

  defp correct_guess?(guess, word) do
    guess
    |> String.contains?(word)
  end
end
