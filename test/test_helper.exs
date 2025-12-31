# Configure ExUnit
ExUnit.start(exclude: [:integration])

# Configure Mox
Mox.defmock(ExVat.MockHTTPClient, for: ExVat.HTTP)
Application.put_env(:ex_vat, :http_client, ExVat.MockHTTPClient)
