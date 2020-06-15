defmodule DrawItWeb.GameChannelTest do
  use DrawItWeb.ChannelCase

  alias DrawIt.Games

  @game_attrs %{
    max_players: 4,
    max_rounds: 4
  }
  @game_player_nicknames ["Alia", "Ghanima", "Leto II"]
  @current_player_nickname "Chani"

  def fixture(:game) do
    {:ok, game} = Games.create_game(@game_attrs)

    Enum.map(@game_player_nicknames, fn nickname ->
      {:ok, _player} = Games.create_player(%{id_game: game.id, nickname: nickname})
    end)

    game
  end

  def join_game(socket_id, join_code, payload \\ %{}, assigns \\ %{}) do
    DrawItWeb.UserSocket
    |> socket(socket_id, assigns)
    |> subscribe_and_join(DrawItWeb.GameChannel, "game:#{join_code}", payload)
  end

  describe "join 'game:<join_code>'" do
    setup [:create_and_join_game]

    test "saves new player", %{game: game, current_player: current_player} do
      assert current_player
      assert current_player in game.players
    end

    test "assigns player to socket", %{socket: socket, current_player: current_player} do
      assert socket.assigns.player == current_player
    end

    test "broadcasts joined message" do
      assert_broadcast "new_message", %{text: "#{@current_player_nickname} joined the game"}
    end

    @tag skip: "not implemented"
    test "reply with error if game has max players", %{game: game} do
      Enum.each(@game_player_nicknames, fn nickname ->
        {:ok, _reply, _socket} = join_game(nickname, game.join_code, %{nickname: nickname})
      end)

      new_player_nickname = "Baron Vladimir Harkonnen"

      assert {:error, :max_players_reached} =
               join_game(new_player_nickname, game.join_code, %{nickname: new_player_nickname})

      updated_game = Games.get_game!(game.id)

      assert updated_game.players == game.players
    end

    test "does not create duplicate player on reconnect", %{
      socket: socket,
      game: game,
      current_player: original_player
    } do
      Process.unlink(socket.channel_pid)
      :ok = close(socket)

      {:ok, _reply, new_socket} =
        join_game("test_user_id", game.join_code, %{
          nickname: @current_player_nickname
        })

      updated_game = Games.get_game!(game.id)

      assert new_socket.assigns.player == original_player
      assert updated_game.players == game.players
    end

    @tag skip: "not implemented"
    test "reply with error if token mismatch on reconnect", %{socket: socket, game: game} do
      Process.unlink(socket.channel_pid)
      :ok = close(socket)

      assert {:error, :token_mismatch} =
               join_game("test_user_id", game.join_code, %{
                 nickname: @current_player_nickname,
                 token: "invalid"
               })
    end
  end

  describe "'new_message'" do
    setup [:create_and_join_game]

    test "broadcasts new_message", %{socket: socket, current_player: current_player} do
      text = "Hello!"
      player = DrawItWeb.PlayerView.render("player.json", %{player: current_player})
      push(socket, "new_message", %{text: text})
      assert_broadcast "new_message", %{text: ^text, player: ^player}
    end
  end

  describe "'round_start'" do
    setup [:create_and_join_game]
  end

  describe "'round_draw'" do
    setup [:create_and_join_game]
  end

  describe "terminate" do
    setup [:create_and_join_game]

    test "broadcasts new_message on leave", %{socket: socket} do
      Process.unlink(socket.channel_pid)
      leave(socket)

      assert_broadcast "new_message", %{text: "#{@current_player_nickname} left the game"}
    end

    test "brodcasts new_message on disconnect", %{socket: socket} do
      Process.unlink(socket.channel_pid)
      :ok = close(socket)

      assert_broadcast "new_message", %{text: "#{@current_player_nickname} disconnected"}
    end
  end

  defp create_and_join_game(_) do
    game = fixture(:game)

    {:ok, _reply, socket} =
      join_game("test_user_id", game.join_code, %{
        nickname: @current_player_nickname
      })

    game = Games.get_game!(game.id)
    current_player = Enum.find(game.players, &(&1.nickname == @current_player_nickname))

    {:ok, socket: socket, game: game, current_player: current_player}
  end
end