-- lua-resty-openidc options
opts = {
  redirect_uri_path = "/redirect_uri",
  discovery = "https://auth.mozilla.auth0.com/.well-known/openid-configuration",
  client_id = "{{ a0clientid }}",
  client_secret = "{{ a0clientsec }}",
  scope = "openid email profile",
  iat_slack = 600,
  redirect_uri_scheme = "https",
  logout_path = "/logout",
  redirect_after_logout_uri = "https://{{ selfservicednszone }}/lnd",
  refresh_session_interval = 900
}
