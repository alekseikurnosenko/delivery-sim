defmodule Sim do
  use HTTPoison.Base

  @moduledoc """
  Documentation for DeliverySim.
  """

  @doc """
  Hello world.

  ## Examples

      iex> DeliverySim.hello()
      :world

  """

  @token "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IlJVUkNNa0ZHTWpsR1FUZ3lPVU5CUkVFMU9EaEJNRGt3UlRaRVEwRkZPVU0xUkRVelF6aERRZyJ9.eyJpc3MiOiJodHRwczovL2Rldi1kZWxpdmVyeS5hdXRoMC5jb20vIiwic3ViIjoiR1l1OHFydUpoTnpMTTFKZWlQaWNVWFpmSXljNjNlUXZAY2xpZW50cyIsImF1ZCI6Imh0dHBzOi8vZGVsaXZlcnkvYXBpIiwiaWF0IjoxNTc3NTc4NjkwLCJleHAiOjE1Nzc2NjUwOTAsImF6cCI6IkdZdThxcnVKaE56TE0xSmVpUGljVVhaZkl5YzYzZVF2IiwiZ3R5IjoiY2xpZW50LWNyZWRlbnRpYWxzIn0.BMs02nO9LgedwJTXjrGxxlLhwEuWXceCOUu0GiJEI-9cUxN7Jv_H7AUyYCFs_9Q8rlZftA4uDKVCtrfV5MEFlSDEWok72xFkr8bpW4Sy2ad7cPm1Xxaz4MwoocRaVLLy0F0YQARrALF8d8-7bCv41v-bOLmLvMxKPR8hk9N90do_uh9wLHfz0YTbLw2lhBBh4B8g2eNd-Wlmqnj_cam6YDIKjHJcj2obGIpOVW78Pe9L2lBjIVN3gOwyhNWW_zBNNHobAz4beu9cjhO2dTZCALBro9ut2w7PPDhjpK1Pu_rkXwik6Ry_7IoEPMjOMbxa6BqfUmubC8CnRbLOdyhc2w"

  def test do
    {:ok, token} = get_token()
  end

  def start do
  end

  def get_token do
    json =
      json(%{
        "client_id" => "<redacted>",
        "client_secret" => "<redacted>",
        "audience" => "https://delivery/api",
        "grant_type" => "client_credentials"
      })

    case HTTPoison.post(
           "https://dev-delivery.auth0.com/oauth/token",
           json,
           "content-type": "application/json"
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        {:ok, response["access_token"]}

      _ ->
        {:error}
    end

    # {:ok, @token}
  end

  def json(payload) do
    Poison.encode!(payload)
  end

  def headers(token) do
    [Authorization: "Bearer #{token}", "content-type": "application/json"]
    # ["content-type": "application/json"]
  end
end
