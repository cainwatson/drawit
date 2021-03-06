defmodule DrawIt.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query

  alias DrawIt.Games.Game
  alias DrawIt.Id
  alias DrawIt.Repo

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
  def list_games do
    Game
    |> Game.with_players()
    |> Game.with_rounds()
    |> Repo.all()
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game!(id) do
    Game
    |> Game.with_players()
    |> Game.with_rounds()
    |> Repo.get!(id)
  end

  @doc """
  Gets a single game from it's join code.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game_by_join_code!("EVsMPJF")
      %Game{}

      iex> get_game_by_join_code!("nOooOpE")
      ** (Ecto.NoResultsError)

  """
  def get_game_by_join_code!(join_code) do
    query =
      from(game in Game,
        where: game.join_code == ^join_code,
        select: game
      )

    query
    |> Game.with_players()
    |> Game.with_rounds()
    |> Repo.one!()
  end

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game(attrs \\ %{}) do
    join_code = Nanoid.generate(7)

    %Game{join_code: join_code}
    |> Game.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:players, [])
    |> Ecto.Changeset.put_assoc(:rounds, [])
    |> Repo.insert()
  end

  @doc """
  Updates a game.

  ## Examples

      iex> update_game(game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game.

  ## Examples

      iex> delete_game(game)
      {:ok, %Game{}}

      iex> delete_game(game)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{source: %Game{}}

  """
  def change_game(%Game{} = game) do
    Game.changeset(game, %{})
  end

  alias DrawIt.Games.Player

  @doc """
  Returns the list of players in a game.

  ## Examples

      iex> list_game_players(42)
      [%Player{}, ...]

  """
  def list_game_players(game_id) do
    query =
      from(player in Player,
        where: player.id_game == ^game_id,
        select: player,
        order_by: player.id
      )

    Repo.all(query)
  end

  @doc """
  Gets a single player.

  Raises `Ecto.NoResultsError` if the Player does not exist.

  ## Examples

      iex> get_player!(123)
      %Player{}

      iex> get_player!(456)
      ** (Ecto.NoResultsError)

  """
  def get_player!(id), do: Repo.get!(Player, id)

  @doc """
  Gets a single player by their token.

  Raises `Ecto.NoResultsError` if the Player does not exist.

  ## Examples

      iex> get_player_by_token!("aia243fjadosf")
      %Player{}

      iex> get_player_by_token!("invalid_token")
      ** (Ecto.NoResultsError)

  """
  def get_player_by_token!(token), do: Repo.get_by!(Player, token: token)

  @doc """
  Creates a player.

  ## Examples

      iex> create_player(%{field: value})
      {:ok, %Player{}}

      iex> create_player(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_player(attrs \\ %{}) do
    token = Id.generate()

    %Player{token: token}
    |> Player.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a player.

  ## Examples

      iex> update_player(player, %{field: new_value})
      {:ok, %Player{}}

      iex> update_player(player, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_player(%Player{} = player, attrs) do
    player
    |> Player.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a player.

  ## Examples

      iex> delete_player(player)
      {:ok, %Player{}}

      iex> delete_player(player)
      {:error, %Ecto.Changeset{}}

  """
  def delete_player(%Player{} = player) do
    Repo.delete(player)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking player changes.

  ## Examples

      iex> change_player(player)
      %Ecto.Changeset{source: %Player{}}

  """
  def change_player(%Player{} = player) do
    Player.changeset(player, %{})
  end

  alias DrawIt.Games.Round

  @doc """
  Returns the list of game_rounds.

  ## Examples

      iex> list_game_rounds()
      [%Round{}, ...]

  """
  def list_game_rounds do
    Round
    |> Round.with_player_drawer()
    |> Repo.all()
  end

  @doc """
  Gets a single round.

  Raises `Ecto.NoResultsError` if the Round does not exist.

  ## Examples

      iex> get_round!(123)
      %Round{}

      iex> get_round!(456)
      ** (Ecto.NoResultsError)

  """
  def get_round!(id) do
    Round
    |> Round.with_player_drawer()
    |> Repo.get!(id)
  end

  @doc """
  Creates a round.

  ## Examples

      iex> create_round(%{field: value})
      {:ok, %Round{}}

      iex> create_round(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_round(attrs \\ %{}) do
    %Round{}
    |> Round.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, round} ->
        {:ok, Repo.preload(round, :player_drawer)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Updates a round.

  ## Examples

      iex> update_round(round, %{field: new_value})
      {:ok, %Round{}}

      iex> update_round(round, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_round(%Round{} = round, attrs) do
    round
    |> Round.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a round.

  ## Examples

      iex> delete_round(round)
      {:ok, %Round{}}

      iex> delete_round(round)
      {:error, %Ecto.Changeset{}}

  """
  def delete_round(%Round{} = round) do
    Repo.delete(round)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking round changes.

  ## Examples

      iex> change_round(round)
      %Ecto.Changeset{source: %Round{}}

  """
  def change_round(%Round{} = round) do
    Round.changeset(round, %{})
  end
end
