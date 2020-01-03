defmodule Sim do
  use HTTPoison.Base
  require Logger

  def login(email, password) do
    client_id = "<redacted>"
    client_secret = "<redacted>"
    audience = "https://delivery/api"

    payload = "grant_type=password&username=#{email}&password=#{password}&audience=#{audience}&scope=&client_id=#{client_id}&client_secret=#{client_secret}"
    case HTTPoison.post("https://dev-delivery.auth0.com/oauth/token", payload, "content-type": "application/x-www-form-urlencoded") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, response} = Poison.decode(body)
        {:ok, response["access_token"]}
      {:ok, %HTTPoison.Response{status_code: 403}} ->
        {:error}
      {:ok, response} ->
        Logger.error(inspect(response))
        {:error}
    end
  end

  def create_user(email, password) do
    token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IlJVUkNNa0ZHTWpsR1FUZ3lPVU5CUkVFMU9EaEJNRGt3UlRaRVEwRkZPVU0xUkRVelF6aERRZyJ9.eyJpc3MiOiJodHRwczovL2Rldi1kZWxpdmVyeS5hdXRoMC5jb20vIiwic3ViIjoiNzdzQkNCekFEeUZVUlBRZ1ExaXBTbTJ2UmJPTHphQXlAY2xpZW50cyIsImF1ZCI6Imh0dHBzOi8vZGV2LWRlbGl2ZXJ5LmF1dGgwLmNvbS9hcGkvdjIvIiwiaWF0IjoxNTc4MDQxMjcyLCJleHAiOjE1NzgxMjc2NzIsImF6cCI6Ijc3c0JDQnpBRHlGVVJQUWdRMWlwU20ydlJiT0x6YUF5Iiwic2NvcGUiOiJyZWFkOmNsaWVudF9ncmFudHMgY3JlYXRlOmNsaWVudF9ncmFudHMgZGVsZXRlOmNsaWVudF9ncmFudHMgdXBkYXRlOmNsaWVudF9ncmFudHMgcmVhZDp1c2VycyB1cGRhdGU6dXNlcnMgZGVsZXRlOnVzZXJzIGNyZWF0ZTp1c2VycyByZWFkOnVzZXJzX2FwcF9tZXRhZGF0YSB1cGRhdGU6dXNlcnNfYXBwX21ldGFkYXRhIGRlbGV0ZTp1c2Vyc19hcHBfbWV0YWRhdGEgY3JlYXRlOnVzZXJzX2FwcF9tZXRhZGF0YSBjcmVhdGU6dXNlcl90aWNrZXRzIHJlYWQ6Y2xpZW50cyB1cGRhdGU6Y2xpZW50cyBkZWxldGU6Y2xpZW50cyBjcmVhdGU6Y2xpZW50cyByZWFkOmNsaWVudF9rZXlzIHVwZGF0ZTpjbGllbnRfa2V5cyBkZWxldGU6Y2xpZW50X2tleXMgY3JlYXRlOmNsaWVudF9rZXlzIHJlYWQ6Y29ubmVjdGlvbnMgdXBkYXRlOmNvbm5lY3Rpb25zIGRlbGV0ZTpjb25uZWN0aW9ucyBjcmVhdGU6Y29ubmVjdGlvbnMgcmVhZDpyZXNvdXJjZV9zZXJ2ZXJzIHVwZGF0ZTpyZXNvdXJjZV9zZXJ2ZXJzIGRlbGV0ZTpyZXNvdXJjZV9zZXJ2ZXJzIGNyZWF0ZTpyZXNvdXJjZV9zZXJ2ZXJzIHJlYWQ6ZGV2aWNlX2NyZWRlbnRpYWxzIHVwZGF0ZTpkZXZpY2VfY3JlZGVudGlhbHMgZGVsZXRlOmRldmljZV9jcmVkZW50aWFscyBjcmVhdGU6ZGV2aWNlX2NyZWRlbnRpYWxzIHJlYWQ6cnVsZXMgdXBkYXRlOnJ1bGVzIGRlbGV0ZTpydWxlcyBjcmVhdGU6cnVsZXMgcmVhZDpydWxlc19jb25maWdzIHVwZGF0ZTpydWxlc19jb25maWdzIGRlbGV0ZTpydWxlc19jb25maWdzIHJlYWQ6aG9va3MgdXBkYXRlOmhvb2tzIGRlbGV0ZTpob29rcyBjcmVhdGU6aG9va3MgcmVhZDplbWFpbF9wcm92aWRlciB1cGRhdGU6ZW1haWxfcHJvdmlkZXIgZGVsZXRlOmVtYWlsX3Byb3ZpZGVyIGNyZWF0ZTplbWFpbF9wcm92aWRlciBibGFja2xpc3Q6dG9rZW5zIHJlYWQ6c3RhdHMgcmVhZDp0ZW5hbnRfc2V0dGluZ3MgdXBkYXRlOnRlbmFudF9zZXR0aW5ncyByZWFkOmxvZ3MgcmVhZDpzaGllbGRzIGNyZWF0ZTpzaGllbGRzIGRlbGV0ZTpzaGllbGRzIHJlYWQ6YW5vbWFseV9ibG9ja3MgZGVsZXRlOmFub21hbHlfYmxvY2tzIHVwZGF0ZTp0cmlnZ2VycyByZWFkOnRyaWdnZXJzIHJlYWQ6Z3JhbnRzIGRlbGV0ZTpncmFudHMgcmVhZDpndWFyZGlhbl9mYWN0b3JzIHVwZGF0ZTpndWFyZGlhbl9mYWN0b3JzIHJlYWQ6Z3VhcmRpYW5fZW5yb2xsbWVudHMgZGVsZXRlOmd1YXJkaWFuX2Vucm9sbG1lbnRzIGNyZWF0ZTpndWFyZGlhbl9lbnJvbGxtZW50X3RpY2tldHMgcmVhZDp1c2VyX2lkcF90b2tlbnMgY3JlYXRlOnBhc3N3b3Jkc19jaGVja2luZ19qb2IgZGVsZXRlOnBhc3N3b3Jkc19jaGVja2luZ19qb2IgcmVhZDpjdXN0b21fZG9tYWlucyBkZWxldGU6Y3VzdG9tX2RvbWFpbnMgY3JlYXRlOmN1c3RvbV9kb21haW5zIHJlYWQ6ZW1haWxfdGVtcGxhdGVzIGNyZWF0ZTplbWFpbF90ZW1wbGF0ZXMgdXBkYXRlOmVtYWlsX3RlbXBsYXRlcyByZWFkOm1mYV9wb2xpY2llcyB1cGRhdGU6bWZhX3BvbGljaWVzIHJlYWQ6cm9sZXMgY3JlYXRlOnJvbGVzIGRlbGV0ZTpyb2xlcyB1cGRhdGU6cm9sZXMgcmVhZDpwcm9tcHRzIHVwZGF0ZTpwcm9tcHRzIHJlYWQ6YnJhbmRpbmcgdXBkYXRlOmJyYW5kaW5nIHJlYWQ6bG9nX3N0cmVhbXMgY3JlYXRlOmxvZ19zdHJlYW1zIGRlbGV0ZTpsb2dfc3RyZWFtcyB1cGRhdGU6bG9nX3N0cmVhbXMiLCJndHkiOiJjbGllbnQtY3JlZGVudGlhbHMifQ.K6mb8-c5iiMTXfD5nqqlQnQaFF9E_RiM0ALOXx_qWzCBbUjqznHub3FscUthLIWPMZUvUfAnxw7k45DUXVyYoDKLlKtJ8NLJUaRB5f815NnC4ZNjq_-nDr6r2O2ZryWjn4KXrz_RCPmFF3st-xx3725d-yeACUHIcq09cjW-4eoGTV2NNCzzH-o4fJJBoUH5Au2JhosVhTtLILxk1qdL9S2K2XyYCdgR_yYqqY7jXxcjRf9Xo_gcMh5GLFxxGvHGhYZ17cjJ9M06AAmEEFtGTXyWm4ttKDhCEsPheg_hcam1YHhHJgjNirHu18t3nFGqOM5JD_dsEQ_OxeVclg5f7A"

    input = %{
      "email" => email,
      "password" => password,
      "connection" => "Username-Password-Authentication"
    }
    case HTTPoison.post("https://dev-delivery.auth0.com/api/v2/users", json(input), headers(token)) do
      {:ok, %HTTPoison.Response{status_code: 201}} ->
        {:ok}
      {:ok, response} ->
        Logger.error(inspect(response))
        {:error}
    end
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

  def random_location() do
    min_lat = 29.624207
    max_lat = 29.939842
    min_lon = -95.571568
    max_lon = -95.190748

    lat = :rand.uniform() * (max_lat - min_lat) + min_lat
    lon = :rand.uniform() * (max_lon - min_lon) + min_lon

    %{
      "latitude" => lat,
      "longitude" => lon
    }

    {lat, lon}
  end
end
